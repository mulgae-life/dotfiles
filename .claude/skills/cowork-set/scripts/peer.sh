#!/usr/bin/env bash
# 상대 에이전트(Codex·Claude Code)의 tmux 세션에 메시지 전송, 작업 종료 대기. 사용법은 usage 참조
# 상태 판정 기준 (화면 + Codex 세션 기록)
#   공통
#     - 1초 사이 화면 변화 → 작업 중
#     - 입력창 안 보임(질문·승인 창) → 작업 중. 키를 넣으면 선택지가 골라짐
#   Codex
#     - 세션 기록의 마지막 턴 사건이 시작 → 작업 중
#     - "resume <id>"로 찾은 기록이 턴 종료 → 입력창만 보이면 유휴
#     - 그 외 → 입력창(› ) 바로 위 내용 줄이 턴 종료 줄("Worked for …")이면 유휴
#     - 턴 종료 뒤에 찍히는 안내(⚠ 경고, 모델·서비스 등급 변경)는 건너뜀
#     - 작업 중 표시줄은 좁은 폭에서 잘려 판정에 미사용
#   Claude Code
#     - 구분선 바로 아래 ❯ 줄(입력창)이 보이고 작업 중 표시줄(BUSY_RE)이 없으면 유휴
# 화면 형식 변경 시 확인 대상: codex_idle, claude_idle, input_box
set -euo pipefail

BUSY_RE='… \([0-9]+[hms] '
# 신호 파일 위치. 두 도구가 같은 곳을 보도록 TMPDIR 미적용
SIGNAL_DIR=${PEER_SIGNAL_DIR:-/tmp/cowork-peer-$(id -u)}

usage() {
  cat >&2 <<'EOF'
사용법:
  peer.sh state <세션>                   작업 중이면 busy, 아니면 idle 출력
  peer.sh send  [--now] <세션> <메시지>  유휴일 때만 한 줄 메시지를 넣고 제출을 확인한다
                                         --now: 작업 중이어도 입력창이 보이면 보낸다(의도 교정 등)
  peer.sh wait  <세션> [최대 분]         유휴로 돌아올 때까지 대기 후 idle 출력 (기본 60분)
                                         작업 시작을 못 봤으면 unseen 출력
  peer.sh signal <이름> <메시지>         중심에 한 줄 신호를 남긴다. 대화창에 넣지 않고 신호 파일에 붙인 뒤,
                                         수신기가 읽을 때까지 1분 기다린다
  peer.sh listen <이름> [최대 분]        신호가 올 때까지 기다렸다가 그 줄을 출력하고 끝난다 (기본 60분)
                                         <이름>은 신호를 받는 중심의 tmux 세션 이름이다(tmux 밖이면 정해 둔 이름)
종료 코드: 2 세션 없음, 3 작업 중이거나 입력창이 가려져 보내지 않음, 4 화면 조회 또는 신호 상태 확인 실패,
          5 대기 시간 초과, 6 Codex·Claude Code 세션이 아님, 7 제출 확인 실패(입력창 확인 필요),
          8 신호를 남겼지만 수신기가 읽지 않음(다음 listen이 읽는다), 9 같은 이름의 수신기가 이미 떠 있음
EOF
  exit 64
}

require_session() {
  tmux has-session -t "$1" 2>/dev/null || { echo "세션 없음: $1" >&2; exit 2; }
}

capture() {
  local out
  out=$(tmux capture-pane -p -t "$1") || { echo "화면 조회 실패: $1" >&2; return 4; }
  perl -CS -pe 's/[\x{2800}-\x{28FF}]//g' <<<"$out"  # 유휴 화면보호기의 점자 그림 제거
}

# "<도구> <pid>" 출력. 실행 파일 이름으로 판별(node로 띄운 경우 두 번째 인자)
peer_tool() {
  local pane found
  pane=$(tmux display-message -p -t "$1" '#{pane_pid}')
  found=$(ps -o pid=,args= -p "$pane" --ppid "$pane" | awk '
    { p = $2; if (p ~ /(^|\/)(node|bun)$/) p = $3; sub(/.*\//, "", p); sub(/\.js$/, "", p) }
    !found && (p == "codex" || p == "claude") { print p, $1; found = 1 }')
  [[ -n $found ]] || { echo "Codex·Claude Code 세션이 아님: $1" >&2; return 6; }
  echo "$found"
}

# Codex 세션 기록을 "<id|guess> <경로>"로 출력. 없으면 빈 문자열
#   id: "resume <id>"로 찾은 기록
#   guess: 같은 폴더에서 가장 최근에 쓰인 기록
codex_rollout() {
  local pid=$1 args cwd since f meta id_file="" id_m=0 other="" other_m=-1 m
  local re='resume([[:space:]]+-[^[:space:]]+)*[[:space:]]+([0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12})'
  args=$(ps -o args= -p "$pid")
  if [[ $args =~ $re ]]; then
    for f in "$HOME"/.codex/sessions/*/*/*/rollout-*-"${BASH_REMATCH[2]}".jsonl; do
      [[ -f $f ]] && { id_file=$f; id_m=$(stat -c %Y "$f"); }
    done
  fi
  cwd=$(readlink "/proc/$pid/cwd")
  since=$(($(date +%s) - $(ps -o etimes= -p "$pid")))
  while IFS= read -r f; do
    [[ $f != "$id_file" ]] || continue
    meta=$(head -c 4000 "$f")
    [[ $meta == *"\"cwd\":\"$cwd\""* ]] || continue
    m=$(stat -c %Y "$f")
    ((m > other_m)) && { other=$f; other_m=$m; }
  done < <(find "$HOME/.codex/sessions" -name 'rollout-*.jsonl' -newermt "@$since" 2>/dev/null)
  # /new로 대화를 바꾸면 같은 프로세스가 새 기록을 씀 → 다른 기록이 모두 앞선 초에 쓰인 경우에만 id 신뢰(수정 시각이 초 단위)
  if [[ -n $id_file ]] && ((other_m < id_m)); then
    echo "id $id_file"
  elif [[ -n $other ]]; then
    echo "guess $other"
  fi
}

# 기록의 마지막 턴 사건을 started 또는 ended로 출력. 중단(turn_aborted)도 종료로 처리. 사건이 없으면 빈 문자열
codex_record_state() {
  local ev
  # grep이 첫 사건에서 멈추면 tac이 SIGPIPE로 끝나므로 파이프 종료 코드 무시
  ev=$(tac "$1" | grep -m1 -oE '"payload":\{"type":"(task_started|task_complete|turn_aborted)"') || true
  case $ev in
    *task_started*) echo started ;;
    ?*) echo ended ;;
  esac
}

# 입력창 줄 출력. 안 보이면 빈 문자열
#   Codex: 들여쓰지 않은 마지막 줄이 "› "일 때 그 줄부터 끝까지. 지난 사용자 메시지도 "› "로 시작하므로 마지막 줄만 인정
#   Claude: 구분선 바로 아래 ❯ 줄부터 다음 구분선 앞까지
input_box() {
  case $2 in
    codex) awk '/^[^ ]/ { box = ""; on = /^› / } on { box = box $0 "\n" } END { printf "%s", box }' <<<"$1" ;;
    claude) awk '/^─/ { if (on) exit; rule = NR; next } /^❯/ && rule == NR - 1 { on = 1 } on { print }' <<<"$1" ;;
  esac
}

# 유휴면 0. $2는 codex_rollout의 출력(없으면 빈 문자열). 추정 기록(guess)은 다른 세션의 것일 수 있어 작업 중 신호로만 사용
codex_idle() {
  local rec="" trust=0
  [[ -z $2 ]] || rec=$(codex_record_state "${2#* }")
  [[ $rec != started ]] || return 1
  [[ ${2%% *} != id || $rec != ended ]] || trust=1
  awk -v trust="$trust" '
    # 모델·서비스 등급 변경 안내면 1. 같은 말로 시작하는 답변 문장과 구분하려고 자리마다 아는 값만 허용
    function notice(s,   scope, n, w, i) {
      if (s ~ /^• Service tier (cleared|set to [a-z][a-z0-9_-]*)$/) return 1
      if (!sub(/^• Model changed to /, "", s)) return 0
      if (sub(/ for this session only$/, "", s)) scope = "session"
      else if (!sub(/ for this conversation$/, "", s)) sub(/ for (Plan|Default) mode\.$/, "", s)
      n = split(s, w, " ")
      if (n < 1 || n > 3 || w[1] !~ "^[A-Za-z0-9][A-Za-z0-9._:/-]*[A-Za-z0-9]$" || w[1] !~ /[0-9-]/) return 0
      i = 2
      if (i <= n && w[i] ~ /^(default|none|minimal|low|medium|high|xhigh|max|ultra|persistent)$/) i++
      if (i <= n && scope == "session" && w[i] ~ /^(standard|fast|flex|ultrafast)$/) i++
      return i > n
    }
    { line[NR] = $0 }
    /^[^ ]/ { last = NR }
    END {
      if (!last || line[last] !~ /^› /) exit 1
      if (trust) exit 0
      # 턴 종료 뒤에 찍혀 입력창 위에 끼어드는 줄은 건너뜀: 빈 줄, 백그라운드 터미널 안내, ⚠ 경고, 변경 안내
      for (i = last - 1; i > 0; i = h - 1) {
        h = i
        if (line[i] !~ /[^ ]/ || line[i] ~ /^ +[0-9]+ background terminals? running/) continue
        if (line[i] ~ /^ *Worked for [0-9]|^■ /) exit 0
        while (h > 0 && line[h] ~ /^ +[^ ]/) h--
        if (line[h] ~ /^⚠/) continue
        s = line[h]
        for (k = h + 1; k <= i; k++) { t = line[k]; sub(/^ +/, "", t); s = s " " t }
        sub(/ +$/, "", s)
        if (!notice(s)) break
      }
      # 대화 전 화면: 머리말이 보이고 입력창 외에 사용자 메시지(› 줄)가 없음
      for (j = 1; j < last; j++) {
        if (line[j] ~ /^› /) asked = 1
        if (line[j] ~ />_ OpenAI Codex/) header = 1
      }
      exit !(header && !asked)
    }' <<<"$1"
}

# 유휴면 0. 조건: 입력창 보임 + 작업 중 표시줄 없음
claude_idle() {
  [[ -n $(input_box "$1" claude) ]] || return 1
  ! grep -qE "$BUSY_RE" <<<"$(tail -n 25 <<<"$1")"
}

# busy 또는 idle 출력(약 1초 소요). 조회 실패는 유휴로 오판하지 않도록 종료 코드 4
probe() {
  local before after
  before=$(capture "$1") || return 4
  sleep 1
  after=$(capture "$1") || return 4
  # $2는 peer_tool이 판별한 도구 → codex_idle 또는 claude_idle 호출
  if [[ $before == "$after" ]] && "${2}_idle" "$after" "${3:-}"; then echo idle; else echo busy; fi
}

# 입력창 상태 출력. 화면 조회 실패면 4
#   hidden: 안 보임, end: 메시지 끝($3, 공백 제외) 있음, fold: 붙여넣기 접힘만 있음, clear: 그 외
box_state() {
  local screen box
  screen=$(capture "$1") || return 4
  box=$(input_box "$screen" "$2")
  [[ -n $box ]] || { echo hidden; return; }
  box=${box//[[:space:]]/}
  if [[ $box == *"$3"* ]]; then
    echo end
  elif [[ $box == *"[Pasted"* ]]; then
    echo fold
  else
    echo clear
  fi
}

cmd_state() {
  local info tool pid rollout=""
  require_session "$1"
  info=$(peer_tool "$1") || exit $?
  read -r tool pid <<<"$info"
  [[ $tool == codex ]] && rollout=$(codex_rollout "$pid")
  probe "$1" "$tool" "$rollout" || exit $?
}

cmd_send() {
  local s=$1 msg=$2 now=$3 info tool pid rollout="" st screen end o i
  local LC_ALL=C.UTF-8  # 메시지를 바이트가 아닌 글자 단위로 자름
  # 접힌 붙여넣기는 끝까지 들어갔는지 확인 불가 → 한 줄만 허용
  [[ $msg != *$'\n'* ]] || { echo "메시지는 한 줄이어야 함 — 여러 줄 내용은 협업 문서에 쓴다" >&2; exit 64; }
  require_session "$s"
  info=$(peer_tool "$s") || exit $?
  read -r tool pid <<<"$info"
  [[ $tool == codex ]] && rollout=$(codex_rollout "$pid")
  if ((now)); then
    screen=$(capture "$s") || exit $?
    [[ -n $(input_box "$screen" "$tool") ]] || { echo "입력창이 가려져 보내지 않음: $s" >&2; exit 3; }
  else
    st=$(probe "$s" "$tool" "$rollout") || exit $?
    [[ $st == idle ]] || { echo "작업 중이거나 입력창이 가려져 보내지 않음: $s" >&2; exit 3; }
  fi
  # 한 번에 넣으면 긴 메시지의 뒤가 잘려 60자씩 분할
  for ((o = 0; o < ${#msg}; o += 60)); do
    tmux send-keys -t "$s" -l -- "${msg:o:60}"
    sleep 0.4
  done
  # 입력창이 줄을 접고 들여 쓰므로 메시지 끝 12자를 공백 제외로 비교
  end=${msg//[[:space:]]/}
  ((${#end} <= 12)) || end=${end: -12}
  # 메시지 끝이 입력창에 들어온 뒤 Enter
  for ((i = 0; i < 15; i++)); do
    sleep 1
    st=$(box_state "$s" "$tool" "$end") || exit 4
    [[ $st != end ]] || break
    [[ $st != hidden ]] || { echo "입력 중 입력창이 가려짐 — 화면 확인 필요: $s" >&2; exit 7; }
  done
  ((i < 15)) || { echo "입력창에 메시지 끝이 안 보여 제출하지 않음 — 화면 확인 필요: $s" >&2; exit 7; }
  # Enter가 자동완성 선택에 쓰일 수 있어 최대 3회. 입력창이 가려지면 그 창의 선택지가 골라지므로 중단
  for ((i = 0; i < 3; i++)); do
    tmux send-keys -t "$s" Enter
    sleep 3
    st=$(box_state "$s" "$tool" "$end") || exit 4
    case $st in
      clear) return 0 ;;
      hidden) echo "Enter 뒤 입력창이 가려져 제출을 확인하지 못함 — 화면 확인 필요: $s" >&2; exit 7 ;;
    esac
  done
  echo "제출 확인 실패 — 입력창에 메시지가 남아 있음: $s" >&2
  exit 7
}

# 신호 파일 경로 설정: SIG_LOG(신호 줄), SIG_CUR(수신기가 읽은 줄 수). 이름이 파일 이름이 되므로 경로 문자 차단
signal_paths() {
  [[ -n $1 && $1 != */* && $1 != .* ]] || { echo "신호 이름으로 쓸 수 없음: $1" >&2; exit 64; }
  mkdir -p -m 700 "$SIGNAL_DIR"
  SIG_LOG=$SIGNAL_DIR/$1.log
  SIG_CUR=$SIGNAL_DIR/$1.cursor
}

# 수신기가 읽은 줄 수 출력(없으면 0). 신호 줄 수와 어긋나면 안 읽은 신호를 읽은 것으로 보게 되므로 오류 종료
signal_seen() {
  local seen=0 n
  # 읽은 줄 수를 먼저 읽어야 그 사이에 온 신호를 어긋남으로 오판하지 않음
  [[ ! -f $SIG_CUR ]] || seen=$(<"$SIG_CUR")
  n=$(wc -l <"$SIG_LOG") || return 4
  # 15자리까지만 허용. 더 길면 셸 정수 범위를 넘어 음수로 바뀜
  [[ $seen =~ ^[0-9]{1,15}$ ]] && ((10#$seen <= n)) || { echo "읽은 줄 수($seen)가 신호 줄 수($n)와 맞지 않음: $SIG_CUR" >&2; return 4; }
  echo "$((10#$seen))"
}

cmd_signal() {
  local name=$1 msg=$2 n seen deadline=$((SECONDS + 60))
  [[ $msg != *$'\n'* ]] || { echo "메시지는 한 줄이어야 함 — 여러 줄 내용은 협업 문서에 쓴다" >&2; exit 64; }
  signal_paths "$name"
  printf '%s %s\n' "$(date '+%F %T')" "$msg" >>"$SIG_LOG"
  n=$(wc -l <"$SIG_LOG") || exit 4
  # 수신기가 재시작 중일 수 있어 읽을 때까지 1분 대기
  while seen=$(signal_seen) || exit 4; ((seen < n)); do
    ((SECONDS < deadline)) || { echo "수신기가 신호를 읽지 않음: $name — 신호는 남아 있어 다음 listen이 읽는다" >&2; exit 8; }
    sleep 1
  done
}

cmd_listen() {
  local name=$1 max_min=$2 seen n deadline
  [[ $max_min =~ ^[0-9]+$ ]] || usage
  max_min=$((10#$max_min))  # 08처럼 0으로 시작하면 bash가 8진수로 해석
  signal_paths "$name"
  # 같은 이름의 수신기가 둘이면 신호 하나를 둘 다 출력 → 하나만 뜨도록 잠금
  exec 9>"$SIGNAL_DIR/$name.lock"
  flock -n 9 || { echo "같은 이름의 수신기가 이미 떠 있음: $name" >&2; exit 9; }
  touch "$SIG_LOG"
  seen=$(signal_seen) || exit 4
  deadline=$((SECONDS + max_min * 60))
  while n=$(wc -l <"$SIG_LOG") || exit 4; ((n <= seen)); do
    ((SECONDS < deadline)) || { echo "대기 시간 초과(${max_min}분) — 신호 없음: $name" >&2; exit 5; }
    sleep 1
  done
  sed -n "$((seen + 1)),${n}p" "$SIG_LOG"
  # 쓰는 도중의 빈 파일을 signal이 읽지 않도록 새 파일로 교체
  echo "$n" >"$SIG_CUR.new"
  mv "$SIG_CUR.new" "$SIG_CUR"
}

cmd_wait() {
  local s=$1 max_min=$2 info tool pid rollout="" st seen=0 idle=0 start_until deadline
  [[ $max_min =~ ^[0-9]+$ ]] || usage
  max_min=$((10#$max_min))  # 08처럼 0으로 시작하면 bash가 8진수로 해석
  require_session "$s"
  info=$(peer_tool "$s") || exit $?
  read -r tool pid <<<"$info"
  [[ $tool == codex ]] && rollout=$(codex_rollout "$pid")
  start_until=$((SECONDS + 20))
  deadline=$((SECONDS + max_min * 60))
  # 제출 직후에는 화면이 아직 안 바뀌었을 수 있어 시작을 20초까지 대기
  while ((SECONDS < start_until)); do
    st=$(probe "$s" "$tool" "$rollout") || exit $?
    [[ $st == busy ]] && { seen=1; break; }
  done
  # 도구 호출 사이의 순간 공백을 유휴로 오판하지 않도록 2회 연속 확인
  while ((idle < 2)); do
    ((SECONDS < deadline)) || { echo "대기 시간 초과(${max_min}분): $s" >&2; exit 5; }
    sleep 4
    st=$(probe "$s" "$tool" "$rollout") || exit $?
    if [[ $st == busy ]]; then seen=1; idle=0; else idle=$((idle + 1)); fi
  done
  # 시작을 못 본 경우: 제출 실패이거나 너무 빨리 끝난 것 → 회신으로 판단
  if ((seen)); then echo idle; else echo unseen; fi
}

[[ $# -ge 1 ]] || usage
cmd=$1
shift
case $cmd in
  state) [[ $# -eq 1 ]] || usage; cmd_state "$1" ;;
  send)
    now=0
    if [[ ${1:-} == --now ]]; then now=1; shift; fi
    [[ $# -eq 2 ]] || usage
    cmd_send "$1" "$2" "$now"
    ;;
  wait) [[ $# -eq 1 || $# -eq 2 ]] || usage; cmd_wait "$1" "${2:-60}" ;;
  signal) [[ $# -eq 2 ]] || usage; cmd_signal "$1" "$2" ;;
  listen) [[ $# -eq 1 || $# -eq 2 ]] || usage; cmd_listen "$1" "${2:-60}" ;;
  *) usage ;;
esac
