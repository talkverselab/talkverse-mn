#!/bin/bash
# 장면 컷(data/review/scenes/<편id>_<n>.jpg)을 공용 그림 저장소 talkverselab/talkversehanja 의
# talkverse_art/scene/mn/<편id>/cut<n>.jpg 로 푸시(이탈리아어앱 push_scenes.sh 를 옮김, 2026-11-19).
# 푸시 뒤 uk 에 「mn pull <커밋>」 → uk 가 M4 ~/talkverse-art 를 받았다고 하면 M4 에서 grok_art.py scene mn.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
C="${SCRATCH:-$HOME/.cache/mn_art_push}"
if [ ! -d "$C/.git" ]; then
  git clone -q --depth 1 --filter=blob:none --sparse https://github.com/talkverselab/talkversehanja.git "$C"
  git -C "$C" sparse-checkout set talkverse_art/scene/mn
  git -C "$C" config user.email talkverse.lab@gmail.com; git -C "$C" config user.name "talkverse-mn session"
fi
git -C "$C" reset -q --hard
git -C "$C" pull -q --rebase origin main
count=0
for f in "$ROOT"/data/review/scenes/r[0-9]_*_[0-9].jpg; do
  b=$(basename "$f" .jpg); id=${b%_*}; n=${b##*_}
  dst="$C/talkverse_art/scene/mn/$id/cut$n.jpg"
  if [ ! -f "$dst" ] || ! cmp -s "$f" "$dst"; then mkdir -p "$(dirname "$dst")"; cp "$f" "$dst"; count=$(( count + 1 )); fi
done
if [ "$count" -eq 0 ]; then echo "새 컷 없음"; exit 0; fi
git -C "$C" add talkverse_art/scene/mn
git -C "$C" commit -q -m "scene/mn: 장면 컷 ${count}장 (talkverse-mn)" && git -C "$C" push -q origin main && echo "푸시: ${count}장 $(git -C "$C" rev-parse --short HEAD)"
