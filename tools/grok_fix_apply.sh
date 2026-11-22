#!/bin/zsh
# Grok 이 고친 편(data/review/grok/fix/<id>.md)을 out 에 덮고 편 JSON 에 반영 → 검사·턴 잠금. 원래 Grok 판은 out/<id>.pre_fix.md 로 남김.
#   zsh tools/grok_fix_apply.sh [<편id>...]   (없으면 fix/ 의 전부)
cd ${0:A:h}/..
ids=("$@"); (( ${#ids} )) || ids=($(ls data/review/grok/fix/*.md 2>/dev/null | xargs -n1 basename | sed 's/\.md$//'))
for e in $ids; do
  [[ -f data/review/grok/out/$e.pre_fix.md ]] || cp data/review/grok/out/$e.md data/review/grok/out/$e.pre_fix.md
  cp data/review/grok/fix/$e.md data/review/grok/out/$e.md
done
python3 tools/grok_io.py import $ids | tail -1
python3 tools/check_dialogues.py --fix-rd $(for e in $ids; do ls app/assets/data/dialogues/R*/*/$e.json; done) | tail -3
python3 tools/turn_lock.py | tail -1
