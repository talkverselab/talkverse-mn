#!/bin/zsh
# 몽골어 Gemini 검수(gemini_loop.sh)가 끝나면 다음 소수언어를 같은 크롬(M4 9235, 4 Argon)으로 이어서 검수한다(사용자 지시 2026-11-11 「몽골어 다음 소수언어도 제미나이작업은 계속」).
# 언어마다: 그 저장소의 프롬프트 도구로 목록을 다시 만들고(답이 있는 편은 빠짐) → mn 의 gemini_batch.py(-j 1 --gap 60). 한도면 20분 쉬고 탭 새로고침, BLOCKED 면 멈춤.
# 반영(실제 오류만 고치기)은 세션이 따로 한다 — 이 스크립트는 답만 모은다.
cd ${0:A:h}/..
LOG=data/review/gemini/log.txt
until grep -q '^끝' $LOG; do grep -q 'BLOCKED 멈춤' $LOG && exit 2; sleep 300; done
reload() { python3 -c "
import json,urllib.request,websocket
t=[x for x in json.load(urllib.request.urlopen('http://127.0.0.1:9235/json')) if x['type']=='page'][0]
w=websocket.create_connection(t['webSocketDebuggerUrl'].replace('localhost','127.0.0.1'),suppress_origin=True);w.send(json.dumps({'id':1,'method':'Page.reload'}))"; sleep 10; }
# 미얀마어: Grok 재작성이 끝난 편 먼저, 아직 초안인 R3 14편은 맨 뒤
MY=~/talkverse/my; MLOG=$MY/data/review/gemini_log.txt
LATE="r3_life_b5 r3_love_b3 r3_love_b4 r3_love_b5 r3_travel_b1 r3_travel_b2 r3_travel_b3 r3_travel_b4 r3_travel_b5 r3_work_b1 r3_work_b2 r3_work_b3 r3_work_b4 r3_work_b5"
ALL=($(ls $MY/app/assets/data/dialogues/R*/*/*.json | xargs -n1 basename | sed 's/\.json$//' | sort))
LATE_A=(${=LATE}); IDS=(${ALL:|LATE_A}); IDS+=($LATE_A)
reload
while true; do
  (cd $MY/app && python3 tools/grok/gemini_prompt.py --list $IDS) > $MY/data/review/gemini_list.tsv
  [[ -s $MY/data/review/gemini_list.tsv ]] || { echo "끝 my $(date +%H:%M)" | tee -a $MLOG >> $LOG; exit 0; }
  GEMINI_CDP_PORT=9235 /usr/bin/python3 tools/gemini_batch.py $MY/data/review/gemini_list.tsv -j 1 --gap 60 >> $MLOG 2>&1
  tail -3 $MLOG | grep -q BLOCKED && { echo "BLOCKED 멈춤 my $(date +%H:%M)" | tee -a $MLOG >> $LOG; exit 2; }
  echo "한도 대기 my $(date +%H:%M)" >> $MLOG; sleep 1200; reload
done
