#!/bin/zsh
# 회화 Grok 재작성 회차(PC 크롬 9253, 전문가 모드) — 헝가리어앱 grok_rewrite_run.sh 를 옮김(2026-11-09).
# 방 하나에 N편 — 첫 메시지만 규칙 첨부, 이후 파일 이름 한 줄(사용자 지시: 프롬프트 최소화).
#   python3 tools/grok_io.py export <편id>...   → data/review/grok/src/<id>.txt
#   zsh tools/grok_rewrite_run.sh <편id>...     → data/review/grok/out/<id>.md, 로그 data/review/grok/run.log
#   python3 tools/grok_io.py import <편id>...   → 편 JSON 에 반영(검사기로 확인)
# 전제: PC 크롬 9253(바탕화면 grok_pc_start.bat), M6 에서 ssh -fN -L 9253:127.0.0.1:9253 pc, 쿠키 동기화·전문가 모드 끝.
cd "$(dirname "$0")/.."
export GROK_CDP_PORT=9253
chat="${GROK_CHAT:-}"
for id in "$@"; do
  out=data/review/grok/out/$id.md
  [[ -s $out ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then
    print -r -- "첨부한 rewrite_grok_mn.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt" > /tmp/grok_mn_first.txt
    r=$(python3 tools/grok_text.py /tmp/grok_mn_first.txt $out tools/prompts/rewrite_grok_mn.md data/review/grok/src/$id.txt 2>&1)
  else
    r=$(python3 tools/grok_text.py -m "$id.txt" $out data/review/grok/src/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E '저장|LIMIT|전문가' | tr '\n' ' ')" | tee -a data/review/grok/run.log
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done
echo "끝 $chat" | tee -a data/review/grok/run.log
