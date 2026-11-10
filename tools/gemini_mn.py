#!/usr/bin/env python3
"""Gemini 검수 프롬프트·목록 만들기(몽골어). 틀 = tools/prompts/review_gemini_mn.md.
  python3 tools/gemini_mn.py [편id…]   → data/review/gemini/prompts/<편>.txt + data/review/gemini/list.tsv (이미 답이 있는 편은 뺀다)
  보내기: GEMINI_CDP_PORT=9235 /usr/bin/python3 tools/gemini_batch.py data/review/gemini/list.tsv -j 1 --gap 60"""
import glob, json, pathlib, re, sys
R = pathlib.Path(__file__).resolve().parent.parent
T = re.search(r'```\n(.*?)```', (R / 'tools/prompts/review_gemini_mn.md').read_text(encoding='utf-8'), re.S).group(1).strip()
P = R / 'data/review/gemini/prompts'; P.mkdir(parents=True, exist_ok=True); O = R / 'data/review/dialogues'; O.mkdir(parents=True, exist_ok=True)
want = set(sys.argv[1:]); rows = []
for f in sorted(glob.glob(str(R / 'app/assets/data/dialogues/R*/*/*.json'))):
    e = json.load(open(f, encoding='utf-8')); ep = e['id']
    if want and ep not in want: continue
    out = O / f'{ep}_gemini.md'
    if out.exists() and not want: continue
    roles = ', '.join(f"{k}={'학습자' if v == '{name}' else v}" for k, v in e['speakers'].items())
    lines = '\n'.join(f"{t['num']}. {t['speaker']}: {t['tl']}  — {t['ko']}" for t in e['turns'])
    txt = T.replace('{code}', ep).replace('{roles}', roles).replace('{scene}', e['scene']).replace('{{name}}', '{name}').replace('{lines}', lines)
    (P / f'{ep}.txt').write_text(txt, encoding='utf-8'); rows.append(f"{P / f'{ep}.txt'}\t{out}")
(R / 'data/review/gemini/list.tsv').write_text('\n'.join(rows) + '\n', encoding='utf-8'); print(len(rows), '편')
