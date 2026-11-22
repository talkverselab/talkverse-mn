#!/bin/zsh
# Gemini 한도 동안 크롬을 꺼 두었다가(크롬 규칙 2026-11-22) 정한 시각에 다시 켜고 몽골어 루프를 잇는다.
#   zsh tools/gemini_resume_mn.sh <HH:MM>
cd ${0:A:h}/..
until [[ $(date +%H:%M) == $1 ]]; do sleep 30; done
ld=$(ssh macmini4 'sysctl -n vm.loadavg' | awk '{print int($2)}'); [[ $ld -ge 20 ]] && { echo "M4 부하 $ld — 시작 안 함 $(date +%H:%M)" >> data/review/gemini/log.txt; exit 1; }
ssh macmini4 'open -na "Google Chrome" --args --remote-debugging-port=9235 --remote-debugging-address=127.0.0.1 --user-data-dir=$HOME/chrome-grok-mn --no-first-run https://gemini.google.com/app'; sleep 15
ssh -fN -o ServerAliveInterval=30 -o ExitOnForwardFailure=yes -L 9235:127.0.0.1:9235 macmini4; sleep 2
echo "=== 다시 켬 $(date +%H:%M)" >> data/review/gemini/log.txt
zsh tools/gemini_loop_mn.sh; rc=$?
ssh macmini4 'pkill -f "user-data-dir=/Users/talkverse/chrome-grok-mn"'; pkill -f "L 9235:127.0.0.1:9235"
echo "loop rc=$rc — 크롬 9235 끔 $(date +%H:%M)" >> data/review/gemini/log.txt
