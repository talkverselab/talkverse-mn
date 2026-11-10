#!/bin/zsh
# Gemini 검수 전체를 끝까지: 한도(BADMODEL Flash-Lite)에 걸리면 20분 쉬고 탭을 새로 고친 뒤 다시. BLOCKED 면 멈춘다.
cd ${0:A:h}/..
LOG=data/review/gemini/log.txt
while true; do
  python3 tools/gemini_mn.py | grep -q '^0 편' && { echo "끝 $(date +%H:%M)" >> $LOG; exit 0; }
  GEMINI_CDP_PORT=9235 /usr/bin/python3 tools/gemini_batch.py data/review/gemini/list.tsv -j 1 --gap 60 >> $LOG 2>&1
  tail -3 $LOG | grep -q BLOCKED && { echo "BLOCKED 멈춤 $(date +%H:%M)" >> $LOG; exit 2; }
  echo "한도 대기 $(date +%H:%M)" >> $LOG; sleep 1200
  python3 -c "
import json,urllib.request,websocket
t=[x for x in json.load(urllib.request.urlopen('http://127.0.0.1:9235/json')) if x['type']=='page'][0]
w=websocket.create_connection(t['webSocketDebuggerUrl'].replace('localhost','127.0.0.1'),suppress_origin=True);w.send(json.dumps({'id':1,'method':'Page.reload'}))"
  sleep 10
done
