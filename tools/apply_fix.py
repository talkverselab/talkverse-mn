#!/usr/bin/env python3
"""Gemini 검수 반영 — 고친 턴만 바꾸고 rd 는 비워 check_dialogues --fix-rd 가 다시 채운다. 편 JSON `review` 에 한 줄.
  python3 tools/apply_fix.py <fix.json>   fix.json = {편id: {"turns": {"<번호>": {"tl":…, "ko":…, "note":…}}, "review": "반영 내역 한 줄"}}"""
import glob, json, pathlib, subprocess, sys
R = pathlib.Path(__file__).resolve().parent.parent
EP = {pathlib.Path(p).stem: p for p in glob.glob(str(R / 'app/assets/data/dialogues/R*/*/*.json'))}
F = json.load(open(sys.argv[1], encoding='utf-8')); done = []
for ep, x in F.items():
    p = EP[ep]; d = json.load(open(p, encoding='utf-8'))
    for t in d['turns']:
        c = x.get('turns', {}).get(str(t['num']))
        if not c: continue
        if 'tl' in c and c['tl'] != t['tl']: t['rd'] = ''
        t.update({k: v for k, v in c.items() if k != 'note'})  # fix 의 note 는 고친 이유 — 턴 note(어휘 설명)를 덮지 않는다
    d['review'] = 'Gemini 4 Argon 검수 반영 2026-11-10 — ' + x['review']
    miss = [w for w in d.get('expressions', []) if not any(w.lower() in t['tl'].lower() for t in d['turns'])]
    if miss: print(ep, '표현 빠짐', miss)
    json.dump(d, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=1); open(p, 'a').write('\n'); done.append(p)
subprocess.run(['python3', str(R / 'tools/check_dialogues.py'), '--fix-rd', *done])
print(len(done), '편 반영')
