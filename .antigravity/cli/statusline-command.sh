#!/bin/bash
# Antigravity CLI(agy) statusLine 명령어 — .claude/statusline-command.sh와 같은 배치
# 표시 항목: prj dir | model | effort | context% | 5h/7d 쿼터 사용률
# 페이로드는 Claude Code와 같은 골격이나 쿼터는 remaining_fraction(남은 비율)이고
# 버킷이 gemini-*·3p-*(Claude·GPT 모델)로 나뉜다

input=$(cat)

# 프로젝트 디렉토리 (~ 치환)
prj_dir=$(echo "$input" | jq -r '.workspace.project_dir // .cwd // empty')
[ -z "$prj_dir" ] && prj_dir=$(pwd)
prj_dir="${prj_dir/#$HOME/\~}"

# 모델 표시명 (괄호 접미사 제거: "Gemini 3.8 Flash (High)" → "Gemini 3.8 Flash")
model=$(echo "$input" | jq -r '.model.display_name // empty' | sed 's/ *(.*//')

# 노력 수준(effort)
effort=$(echo "$input" | jq -r '.model.effort // empty')

# 컨텍스트 사용률
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ── 출력 조합 ─────────────────────────────────
parts=""

# prj dir (파랑)
parts=$(printf "\033[01;34m%s\033[00m" "$prj_dir")

# 모델 (노란색)
[ -n "$model" ] && parts="$parts $(printf "\033[0;33m%s\033[00m" "$model")"

# 노력 수준 (회색)
[ -n "$effort" ] && parts="$parts $(printf "\033[0;37m[%s]\033[00m" "$effort")"

# ── 2번째 줄: 컨텍스트 + 쿼터 ──────────
line2=""

# 컨텍스트 사용률 (사용률에 따라 색상 변경)
if [ -n "$used_pct" ]; then
  pct_int=$(printf "%.0f" "$used_pct")
  if [ "$pct_int" -ge 80 ]; then
    ctx_color="\033[1;31m"   # 빨강 bold
  elif [ "$pct_int" -ge 60 ]; then
    ctx_color="\033[1;33m"   # 노랑 bold
  else
    ctx_color="\033[1;36m"   # 청록 bold
  fi
  line2=$(printf "${ctx_color}ctx %s%%\033[00m" "$pct_int")
fi

# 쿼터 (5h/7d 사용률, 색상으로 위험도 표시)
rate_color() {
  local pct=$1
  if [ "$pct" -ge 80 ]; then printf "\033[1;31m"    # 빨강 bold
  elif [ "$pct" -ge 60 ]; then printf "\033[1;33m"   # 노랑 bold
  else printf "\033[1;36m"                            # 청록 bold
  fi
}

# 버킷 선택: Gemini 모델은 gemini-*, Claude·GPT 모델은 3p-*
case "$model" in
  Gemini*) bucket="gemini" ;;
  *)       bucket="3p" ;;
esac

# remaining_fraction(남은 비율) → 사용률 %
five_h=$(echo "$input" | jq -r --arg b "$bucket" '.quota[$b + "-5h"].remaining_fraction // empty | (1 - .) * 100')
seven_d=$(echo "$input" | jq -r --arg b "$bucket" '.quota[$b + "-weekly"].remaining_fraction // empty | (1 - .) * 100')
seven_d_reset=$(echo "$input" | jq -r --arg b "$bucket" '.quota[$b + "-weekly"].reset_time // empty')

if [ -n "$five_h" ] || [ -n "$seven_d" ]; then
  limit_parts=""
  if [ -n "$five_h" ]; then
    pct_int=$(printf "%.0f" "$five_h")
    limit_parts="$(rate_color "$pct_int")5h ${pct_int}%\033[00m"
  fi
  if [ -n "$seven_d" ]; then
    pct_int=$(printf "%.0f" "$seven_d")
    [ -n "$limit_parts" ] && limit_parts="$limit_parts \033[0;90m·\033[00m "
    limit_parts="${limit_parts}$(rate_color "$pct_int")7d ${pct_int}%\033[00m"
    # 7일 한도 초기화 일시 (KST)
    if [ -n "$seven_d_reset" ]; then
      reset_kst=$(TZ=Asia/Seoul date -d "$seven_d_reset" '+%-m/%-d %H:%M' 2>/dev/null)
      [ -n "$reset_kst" ] && limit_parts="${limit_parts} \033[0;90m→${reset_kst}\033[00m"
    fi
  fi
  [ -n "$line2" ] && line2="$line2 $(printf '\033[1;90m│\033[00m') "
  line2="${line2}$(printf "%b" "$limit_parts")"
fi

# 2줄 조합: line2가 있으면 줄바꿈 후 출력
if [ -n "$line2" ]; then
  printf "%s\n%s" "$parts" "$line2"
else
  printf "%s" "$parts"
fi
