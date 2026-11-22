#!/bin/zsh
# Gemini 검수 3편 묶음 루프(사용자 결정 2026-11-11 「한 메시지에 3편씩 묶어 보내기」): 몽골어만(2026-11-22 Grok 다시 쓴 138편).
# 회차마다 언어별 편 목록을 다시 만들고(답 있는 편 빠짐) → 3편씩 묶음 → gemini_batch(-j 1 --gap 60) → 편별로 나눔.
# 한도(BADMODEL Flash-Lite)면 20분 쉬고 탭 새로고침, BLOCKED 면 멈춤(우회 금지). 반영은 세션이 따로.
cd ${0:A:h}/..
LOG=data/review/gemini/log.txt; B=data/review/gemini/bundle
PORT=${GEMINI_CDP_PORT:-9226}  # 2026-11-23: uk 9226(사용자가 직접 로그인한 공용 Gemini 크롬) — 끄지 말고 탭만 닫음, 쿠키 복사 금지
reload() { python3 -c "
import json,urllib.request,websocket
t=[x for x in json.load(urllib.request.urlopen('http://127.0.0.1:$PORT/json')) if x['type']=='page'][0]
w=websocket.create_connection(t['webSocketDebuggerUrl'].replace('localhost','127.0.0.1'),suppress_origin=True);w.send(json.dumps({'id':1,'method':'Page.reload'}))"; sleep 10; }
MY=~/talkverse/my
LATE=(r3_life_b5 r3_love_b3 r3_love_b4 r3_love_b5 r3_travel_b1 r3_travel_b2 r3_travel_b3 r3_travel_b4 r3_travel_b5 r3_work_b1 r3_work_b2 r3_work_b3 r3_work_b4 r3_work_b5)
ALL=($(ls $MY/app/assets/data/dialogues/R*/*/*.json | xargs -n1 basename | sed 's/\.json$//' | sort)); MYIDS=(${ALL:|LATE}); MYIDS+=($LATE)
list() {  # $1 = mn|my → 편별 목록 파일 경로를 출력
  if [[ $1 == mn ]]; then python3 tools/gemini_mn.py >/dev/null; echo data/review/gemini/list.tsv
  else (cd $MY/app && python3 tools/grok/gemini_prompt.py --list $MYIDS) > $MY/data/review/gemini_list.tsv; echo $MY/data/review/gemini_list.tsv; fi
}
for L in mn; do
  [[ -f $B/$L/map.json ]] && python3 tools/gemini_bundle.py split $B/$L >> $LOG  # 2026-11-22: 멈췄다 다시 켤 때 받은 답을 먼저 나눔(make 가 폴더를 새로 만들어 답이 지워짐)
  while true; do
    f=$(list $L); [[ -s $f ]] || { echo "끝 $L $(date +%H:%M)" >> $LOG; break; }
    python3 tools/gemini_bundle.py make $f $B/$L >> $LOG
    echo "$(date +%H:%M) $(GEMINI_CDP_PORT=$PORT /usr/bin/python3 tools/gemini_pick.py)" >> $LOG   # 「심층 분석」 고르기(hu b4445a6)
    GEMINI_CDP_PORT=$PORT /usr/bin/python3 tools/gemini_batch.py $B/$L/bundles.tsv -j 1 --gap 60 >> $LOG 2>&1
    python3 tools/gemini_bundle.py split $B/$L >> $LOG
    tail -4 $LOG | grep -q BLOCKED && { echo "BLOCKED 멈춤 $L $(date +%H:%M)" >> $LOG; exit 2; }
    tail -4 $LOG | grep -q LOGGEDOUT && { echo "LOGGEDOUT 멈춤 $L $(date +%H:%M) — 구글 로그인 필요(재시도 안 함)" >> $LOG; exit 4; }
    tail -4 $LOG | grep -q BADMODEL || { tail -1 $LOG | grep -q '나눔 0 ' || continue; }   # 한도 아니면(묶음 다 보냄) 바로 다음 회차
    echo "한도 대기 $L $(date +%H:%M)" >> $LOG; sleep 1200; reload
  done
done
echo "끝 전체 $(date +%H:%M)" >> $LOG
