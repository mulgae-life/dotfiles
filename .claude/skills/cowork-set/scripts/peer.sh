#!/usr/bin/env bash
# 상대 에이전트(Codex·Claude Code)의 tmux 세션에 메시지를 넣고, 작업이 끝날 때까지 기다린다.
# 중심(대표님이 주로 대화하는 쪽)에 알리는 신호는 대화창에 넣지 않고 신호 파일로 주고받는다.
# 도구는 세션의 실행 파일로 가리고, 상태는 화면으로 추정한다. 1초 사이에 화면이 바뀌면 작업 중이고, 그 밖에는 도구별로 본다.
# 두 도구 모두 입력창이 안 보이면(질문·승인 창 등) 작업 중으로 본다. 그 창에 키를 넣으면 선택지가 대신 골라진다.
#   Codex: 들여쓰지 않은 마지막 줄이 입력창(› )이고 그 바로 위 내용 줄이 턴 종료 줄("  Worked for …")이면 유휴.
#          지난 사용자 메시지도 "› "로 시작하므로 마지막 줄만 입력창으로 인정한다.
#          작업 중 표시줄은 폭이 좁으면 잘려 "esc to interrupt"가 사라지므로 판정에 쓰지 않는다.
#          세션 기록(rollout)의 마지막 턴 사건이 시작이면 화면과 관계없이 작업 중이다. "resume <id>"로 찾은 기록이
#          턴 종료면 입력창 위에 무엇이 있든 입력창만 보이면 유휴다. 다만 같은 폴더에 그보다 최근에 쓰인 기록이
#          있으면(/new로 대화를 바꾼 경우 등) id 기록을 믿지 않는다.
#          유휴 화면보호기의 점자 그림(U+2800~U+28FF)은 캡처에서 지운다.
#   Claude Code: 구분선 바로 아래 ❯ 줄(입력창)이 보이고 "<동사>… (Ns ·"·"(1m 5s ·" 표시줄(BUSY_RE)이 없으면 유휴.
# 메시지는 한 줄만 보낸다. 60자씩 나눠 넣고(한 번에 넣으면 긴 메시지의 뒤가 잘린다), 입력창에 메시지 끝이 보인 뒤 Enter를 친다.
# 입력창이 보이고 메시지 끝이 빠져야 제출로 본다. 입력창이 가려지면 Enter를 더 치지 않고 제출 확인 실패로 멈춘다.
# 신호(signal)는 파트너가 중심에 알릴 것(회신 완료, 질문 등)을 남기는 한 줄이다. 중심 대화창에 사용자 입력처럼 남지 않도록
# 신호 파일에 붙인다. listen은 새 줄이 붙는 순간 그 줄을 출력하고 끝난다. 중심이 Claude면 백그라운드로 띄워 두고,
# 명령이 끝나면 Claude Code가 Claude를 깨운다. 중심이 Codex면 요청을 보낸 턴 안에서 끝나기를 기다린다(유휴 상태의 Codex는
# 깨어나지 않는다). 수신기가 꺼져 있는 동안 온 신호는 파일에 남아 다음 listen이 바로 읽는다.
# signal은 수신기가 그 줄을 읽었는지(읽은 줄 수 파일)까지 확인한다. 중심이 파트너에 알릴 때는 send로 입력창에 넣는다.
# 검증 버전: Codex 0.167.2, Claude Code 2.1.323 — 화면 형식이 바뀌면 codex_idle·claude_idle·input_box를 확인한다.
set -euo pipefail

BUSY_RE='… \([0-9]+[hms] '
# 신호 파일을 두는 곳. 두 도구가 같은 곳을 보도록 TMPDIR을 따르지 않는다
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
  perl -CS -pe 's/[\x{2800}-\x{28FF}]//g' <<<"$out"
}

# "<도구> <pid>"를 출력한다. 실행 파일 이름으로 가리며, node로 띄웠으면 두 번째 인자가 실행 파일이다
peer_tool() {
  local pane found
  pane=$(tmux display-message -p -t "$1" '#{pane_pid}')
  found=$(ps -o pid=,args= -p "$pane" --ppid "$pane" | awk '
    { p = $2; if (p ~ /(^|\/)(node|bun)$/) p = $3; sub(/.*\//, "", p); sub(/\.js$/, "", p) }
    !found && (p == "codex" || p == "claude") { print p, $1; found = 1 }')
  [[ -n $found ]] || { echo "Codex·Claude Code 세션이 아님: $1" >&2; return 6; }
  echo "$found"
}

# Codex 세션 기록을 "<id|guess> <경로>"로 출력한다. "resume <id>"로 띄웠으면 그 id로 찾는다(id).
# 아니면, 또는 프로세스가 뜬 뒤 같은 폴더에서 다른 기록이 id 기록과 같은 초나 그 뒤에 쓰였으면 그중 가장 최근 기록으로
# 추정한다(guess). 못 찾으면 빈 문자열이다(첫 대화 전 등)
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
  # /new로 대화를 바꾸면 같은 프로세스가 새 기록을 쓴다. 수정 시각은 초 단위라 같은 초면 어느 쪽이 현재 대화인지 모르므로,
  # 다른 기록이 모두 id 기록보다 앞선 초에 쓰였을 때만 id로 믿는다
  if [[ -n $id_file ]] && ((other_m < id_m)); then
    echo "id $id_file"
  elif [[ -n $other ]]; then
    echo "guess $other"
  fi
}

# 기록의 마지막 턴 사건을 started 또는 ended로 출력한다. 중단(turn_aborted)도 턴 종료로 센다. 사건이 없으면 빈 문자열
codex_record_state() {
  local ev
  # grep이 첫 사건에서 멈추면 tac이 SIGPIPE로 끝나므로 파이프 종료 코드는 보지 않는다
  ev=$(tac "$1" | grep -m1 -oE '"payload":\{"type":"(task_started|task_complete|turn_aborted)"') || true
  case $ev in
    *task_started*) echo started ;;
    ?*) echo ended ;;
  esac
}

# 입력창 줄들. Codex는 들여쓰지 않은 마지막 줄이 "› "일 때 그 줄부터 끝까지, Claude는 구분선 바로 아래 ❯ 줄부터 다음 구분선 앞까지.
# 입력창이 안 보이면 빈 문자열이다
input_box() {
  case $2 in
    codex) awk '/^[^ ]/ { box = ""; on = /^› / } on { box = box $0 "\n" } END { printf "%s", box }' <<<"$1" ;;
    claude) awk '/^─/ { if (on) exit; rule = NR; next } /^❯/ && rule == NR - 1 { on = 1 } on { print }' <<<"$1" ;;
  esac
}

# 유휴면 0. $2는 codex_rollout의 출력(없으면 빈 문자열).
# 기록이 턴 시작이면 작업 중이다. id로 찾은 기록이 턴 종료면 입력창만 보이면 유휴이고, 그 밖에는 화면 규칙으로 본다.
# 추정한 기록은 다른 세션의 것일 수 있어 작업 중 신호로만 쓴다
codex_idle() {
  local rec="" trust=0
  [[ -z $2 ]] || rec=$(codex_record_state "${2#* }")
  [[ $rec != started ]] || return 1
  [[ ${2%% *} != id || $rec != ended ]] || trust=1
  awk -v trust="$trust" '
    { line[NR] = $0 }
    /^[^ ]/ { last = NR }
    END {
      if (!last || line[last] !~ /^› /) exit 1
      if (trust) exit 0
      # 입력창 위의 빈 줄과 백그라운드 터미널 안내줄은 건너뛴다
      for (i = last - 1; i > 0 && (line[i] !~ /[^ ]/ || line[i] ~ /^ +[0-9]+ background terminals? running/); i--) {}
      if (line[i] ~ /^ *Worked for [0-9]|^■ /) exit 0
      # 대화 전 화면: 머리말이 보이고, 입력창 말고는 사용자 메시지(› 줄)가 없다
      for (j = 1; j < last; j++) {
        if (line[j] ~ /^› /) asked = 1
        if (line[j] ~ />_ OpenAI Codex/) header = 1
      }
      exit !(header && !asked)
    }' <<<"$1"
}

# 유휴면 0. 입력창이 보이고 작업 중 표시줄이 없어야 한다
claude_idle() {
  [[ -n $(input_box "$1" claude) ]] || return 1
  ! grep -qE "$BUSY_RE" <<<"$(tail -n 25 <<<"$1")"
}

# busy 또는 idle을 출력한다(약 1초 걸림). 조회 실패를 유휴로 오판하지 않도록 실패는 종료 코드 4로 돌려준다
probe() {
  local before after
  before=$(capture "$1") || return 4
  sleep 1
  after=$(capture "$1") || return 4
  # $2는 peer_tool이 가린 도구라 codex_idle·claude_idle 중 하나를 부른다
  if [[ $before == "$after" ]] && "${2}_idle" "$after" "${3:-}"; then echo idle; else echo busy; fi
}

# 입력창 상태를 출력한다. hidden 안 보임, end 메시지 끝($3, 공백 제외)이 있음, fold 붙여넣기 접힘만 있음, clear 그 밖.
# 화면 조회 실패면 4
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
  local LC_ALL=C.UTF-8  # 메시지를 바이트가 아니라 글자 단위로 자른다
  # 접힌 붙여넣기는 끝까지 들어갔는지 확인할 수 없다. tmux로는 파일을 가리키는 한 줄만 보낸다
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
  for ((o = 0; o < ${#msg}; o += 60)); do
    tmux send-keys -t "$s" -l -- "${msg:o:60}"
    sleep 0.4
  done
  # 메시지 끝 12자(공백 제외)로 입력창을 확인한다. 입력창은 줄을 접고 들여 쓰므로 공백을 빼고 비교한다
  end=${msg//[[:space:]]/}
  ((${#end} <= 12)) || end=${end: -12}
  # 입력창에 메시지 끝이 들어온 뒤에 Enter를 친다. 끝내 안 보이거나 입력창이 가려지면 제출하지 않고 멈춘다
  for ((i = 0; i < 15; i++)); do
    sleep 1
    st=$(box_state "$s" "$tool" "$end") || exit 4
    [[ $st != end ]] || break
    [[ $st != hidden ]] || { echo "입력 중 입력창이 가려짐 — 화면 확인 필요: $s" >&2; exit 7; }
  done
  ((i < 15)) || { echo "입력창에 메시지 끝이 안 보여 제출하지 않음 — 화면 확인 필요: $s" >&2; exit 7; }
  # Enter가 자동완성 선택 등에 쓰여 제출되지 않을 수 있어, 입력창이 보이는 채로 메시지가 빠질 때까지 세 번까지 친다.
  # 입력창이 가려지면 그 창의 선택지를 고르지 않도록 Enter를 더 치지 않는다
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

# 신호 파일 경로를 SIG_LOG(신호 줄)와 SIG_CUR(수신기가 읽은 줄 수)에 넣는다. 이름이 파일 이름이 되므로 경로 글자를 막는다
signal_paths() {
  [[ -n $1 && $1 != */* && $1 != .* ]] || { echo "신호 이름으로 쓸 수 없음: $1" >&2; exit 64; }
  mkdir -p -m 700 "$SIGNAL_DIR"
  SIG_LOG=$SIGNAL_DIR/$1.log
  SIG_CUR=$SIGNAL_DIR/$1.cursor
}

# 수신기가 읽은 줄 수를 출력한다. 아직 읽은 적이 없으면 0.
# 숫자가 아니거나 신호 줄 수보다 크면 두 파일이 어긋난 것이다. 그대로 두면 읽지 않은 신호를 읽었다고 보게 되므로 오류로 끝낸다
signal_seen() {
  local seen=0 n
  # 신호 줄은 붙기만 하고 읽은 줄 수는 늘기만 한다. 읽은 줄 수를 먼저 읽어야 그 사이에 온 신호를 어긋남으로 보지 않는다
  [[ ! -f $SIG_CUR ]] || seen=$(<"$SIG_CUR")
  n=$(wc -l <"$SIG_LOG") || return 4
  # 15자리까지만 받는다. 더 긴 숫자는 셸 정수 범위를 넘어 음수로 바뀐다
  [[ $seen =~ ^[0-9]{1,15}$ ]] && ((10#$seen <= n)) || { echo "읽은 줄 수($seen)가 신호 줄 수($n)와 맞지 않음: $SIG_CUR" >&2; return 4; }
  echo "$((10#$seen))"
}

cmd_signal() {
  local name=$1 msg=$2 n seen deadline=$((SECONDS + 60))
  [[ $msg != *$'\n'* ]] || { echo "메시지는 한 줄이어야 함 — 여러 줄 내용은 협업 문서에 쓴다" >&2; exit 64; }
  signal_paths "$name"
  printf '%s %s\n' "$(date '+%F %T')" "$msg" >>"$SIG_LOG"
  n=$(wc -l <"$SIG_LOG") || exit 4
  # 수신기가 이 줄까지 읽으면 읽은 줄 수가 따라온다. 수신기가 다시 뜨는 사이일 수 있어 1분까지 기다린다
  while seen=$(signal_seen) || exit 4; ((seen < n)); do
    ((SECONDS < deadline)) || { echo "수신기가 신호를 읽지 않음: $name — 신호는 남아 있어 다음 listen이 읽는다" >&2; exit 8; }
    sleep 1
  done
}

cmd_listen() {
  local name=$1 max_min=$2 seen n deadline
  [[ $max_min =~ ^[0-9]+$ ]] || usage
  max_min=$((10#$max_min))  # 08처럼 앞자리가 0이면 bash가 8진수로 읽는다
  signal_paths "$name"
  # 같은 이름의 수신기가 둘이면 신호 하나를 둘 다 출력하므로 하나만 뜨게 잠근다. 잠금은 수신기가 끝나면 풀린다
  exec 9>"$SIGNAL_DIR/$name.lock"
  flock -n 9 || { echo "같은 이름의 수신기가 이미 떠 있음: $name" >&2; exit 9; }
  touch "$SIG_LOG"
  seen=$(signal_seen) || exit 4
  deadline=$((SECONDS + max_min * 60))
  # 수신기가 꺼져 있는 동안 온 신호도 읽은 줄 수 뒤에 남아 있어, 다시 띄우면 바로 나온다
  while n=$(wc -l <"$SIG_LOG") || exit 4; ((n <= seen)); do
    ((SECONDS < deadline)) || { echo "대기 시간 초과(${max_min}분) — 신호 없음: $name" >&2; exit 5; }
    sleep 1
  done
  sed -n "$((seen + 1)),${n}p" "$SIG_LOG"
  # signal이 읽는 도중의 빈 파일을 보지 않도록 새 파일을 써서 바꿔 놓는다
  echo "$n" >"$SIG_CUR.new"
  mv "$SIG_CUR.new" "$SIG_CUR"
}

cmd_wait() {
  local s=$1 max_min=$2 info tool pid rollout="" st seen=0 idle=0 start_until deadline
  [[ $max_min =~ ^[0-9]+$ ]] || usage
  max_min=$((10#$max_min))  # 08처럼 앞자리가 0이면 bash가 8진수로 읽는다
  require_session "$s"
  info=$(peer_tool "$s") || exit $?
  read -r tool pid <<<"$info"
  [[ $tool == codex ]] && rollout=$(codex_rollout "$pid")
  start_until=$((SECONDS + 20))
  deadline=$((SECONDS + max_min * 60))
  # 제출 직후에는 화면이 아직 안 바뀌었을 수 있으므로 20초까지 시작을 기다린다
  while ((SECONDS < start_until)); do
    st=$(probe "$s" "$tool" "$rollout") || exit $?
    [[ $st == busy ]] && { seen=1; break; }
  done
  # 도구 호출 사이의 순간 공백을 유휴로 오판하지 않도록 두 번 연속 확인한다
  while ((idle < 2)); do
    ((SECONDS < deadline)) || { echo "대기 시간 초과(${max_min}분): $s" >&2; exit 5; }
    sleep 4
    st=$(probe "$s" "$tool" "$rollout") || exit $?
    if [[ $st == busy ]]; then seen=1; idle=0; else idle=$((idle + 1)); fi
  done
  # 시작을 못 봤으면 제출이 안 됐거나 너무 빨리 끝난 것이다 — 회신으로 가린다
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
