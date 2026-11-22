#!/bin/zsh
# 회화 Grok 재작성 회차(PC 크롬 9253, 빠른 모드 — 사용자 지시 2026-11-18 「Grok 빠른 모드 진행」, 11-22 「137편 다시 쓰기 — 다시 써야지」).
# 방 하나에 최대 25편(uk 11-17 「20~30회차마다 새 방」) — 방 첫 메시지만 규칙 첨부, 이후 파일 이름 한 줄 + 그 편 원고 첨부.
#   python3 tools/grok_io.py export <편id>...   → data/review/grok/src/<id>.txt
#   zsh tools/grok_rewrite_run.sh <편id>...     → data/review/grok/out/<id>.md, 로그 data/review/grok/run.log
#   python3 tools/grok_io.py import <편id>...   → 편 JSON 에 반영(형식만, 대사는 Grok 그대로) → check_dialogues.py
# 3분 상한(넘으면 생성 중지·답 버림) · 끝 줄이 비거나 줄 수가 원고와 다르면(답 끊김) 버리고 다음 방에서 다시.
# 전제: PC 크롬 9253(Grok-Chrome-mn-9253), M6 에서 ssh -fN -L 9253:127.0.0.1:9253 pc, 로그인·빠른 모드 확인 끝.
cd "$(dirname "$0")/.."
export GROK_CDP_PORT=9253
LOG=data/review/grok/run.log
PER=${PER:-25}
chat="${GROK_CHAT:-}"; n=0; retry=()
rows() { grep -c -E '^[A-Z] \| ' "$1" 2>/dev/null || echo 0; }
one() {
  local id=$1 out=data/review/grok/out/$1.md r rc
  if [[ -z $chat ]]; then
    print -r -- "첨부한 rewrite_grok_mn.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt" > /private/tmp/claude-501/grok_mn_first.txt
    r=$(python3 tools/grok_text.py /private/tmp/claude-501/grok_mn_first.txt $out tools/prompts/rewrite_grok_mn.md data/review/grok/src/$id.txt 2>&1)
  else
    r=$(python3 tools/grok_text.py -m "$id.txt" $out data/review/grok/src/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  local c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  if [[ $rc -eq 0 && $(rows $out) -ne $(rows data/review/grok/src/$id.txt) ]]; then
    echo "$(date +%H:%M) $id 줄 수 다름 $(rows $out)/$(rows data/review/grok/src/$id.txt) — 버림" | tee -a $LOG; rm -f $out; rc=5
  fi
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E '저장|LIMIT|빠른|시간초과' | tr '\n' ' ')" | tee -a $LOG
  [[ $rc -eq 4 ]] && rm -f $out
  return $rc
}
for id in "$@"; do
  [[ -s data/review/grok/out/$id.md ]] && { echo "skip $id"; continue; }
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
