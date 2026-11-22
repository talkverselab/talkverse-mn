#!/bin/zsh
# Gemini 지적 → Grok 이 지적된 줄만 고침(2026-11-22, 「Claude 는 문장 손대지 않음」 원칙). PC 크롬 9253, 빠른, 25편마다 새 방, 3분 상한.
#   zsh tools/grok_fix_run.sh <편id>...   → data/review/grok/fix/<id>.md(줄 수가 out 과 같아야 받음) → tools/grok_fix_apply.sh 로 out 교체·import
cd "$(dirname "$0")/.."
export GROK_CDP_PORT=${GROK_CDP_PORT:-9253}  # M4 로 돌릴 땐 GROK_HOST=m4 GROK_CDP_PORT=9235
LOG=data/review/grok/fix/run.log; mkdir -p data/review/grok/fix
PER=${PER:-25}; chat=""; n=0; retry=()
rows() { grep -c -E '^[A-Z] \| ' "$1" 2>/dev/null || echo 0; }
one() {
  local id=$1 out=data/review/grok/fix/$1.md r rc g=data/review/dialogues/$1_gemini.md
  if [[ -z $chat ]]; then
    print -r -- "첨부한 fix_grok_mn.md 가 이 방의 규칙이다(작성 규칙은 rewrite_grok_mn.md). 앞으로는 「<편id> 고침」 한 줄만 보낸다. 첫 편: $id 고침" > /private/tmp/claude-501/grok_mn_fix_first.txt
    r=$(python3 tools/grok_text.py /private/tmp/claude-501/grok_mn_fix_first.txt $out tools/prompts/fix_grok_mn.md tools/prompts/rewrite_grok_mn.md data/review/grok/out/$id.md $g 2>&1 < /dev/null)
  else
    r=$(python3 tools/grok_text.py -m "$id 고침" $out data/review/grok/out/$id.md $g --chat "$chat" 2>&1 < /dev/null)
  fi
  rc=$?
  local c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  if [[ $rc -eq 0 && ( $(rows $out) -ne $(rows data/review/grok/out/$id.md) || $(head -c 200 $out | grep -c "=== $id") -eq 0 ) ]]; then
    echo "$(date +%H:%M) $id 줄 수·머리 다름 — 버림" | tee -a $LOG; rm -f $out; rc=5
  fi
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E '저장|LIMIT|빠른|시간초과' | tr '\n' ' ')" | tee -a $LOG
  [[ $rc -eq 4 ]] && rm -f $out
  return $rc
}
for id in "$@"; do
  [[ -s data/review/grok/fix/$id.md ]] && { echo "skip $id"; continue; }
  (( n >= PER )) && { chat=""; n=0; echo "새 방" | tee -a $LOG; }
  one $id; rc=$?; n=$((n+1))
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤" | tee -a $LOG; exit 3; }
  [[ $rc -ne 0 ]] && retry+=$id
  sleep 10
done
if (( ${#retry} )); then
  echo "다시(새 방): $retry" | tee -a $LOG; chat=""
  for id in $retry; do one $id; [[ $? -eq 3 ]] && exit 3; sleep 10; done
fi
echo "끝 $chat" | tee -a $LOG
