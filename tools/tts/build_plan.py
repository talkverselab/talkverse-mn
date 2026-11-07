#!/usr/bin/env python3
"""회화 파일의 emotion·segs → 음성 감정 계획 data/tts/plan/<편id>.json (형식 = ~/talkverse/ja/data/tts/PLAN_GUIDE.md).
  python3 tools/tts/build_plan.py [편id...]    없으면 R 구조 전체
음성 생성기는 몽골어 음성 모델이 정해진 뒤 이 계획을 읽어 조각마다 그 감정의 참고 음성으로 만든다(사용자 지시 2026-11-07).
읽기 칸: 이모지·기호는 소리로 나오면 안 되니 뺀 글을 세 번째 칸에 둔다. 다른 언어 인용(한글)도 뺀 글로 두고 경고한다."""
import glob, json, pathlib, re, sys
ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / 'data/tts/plan'
CAST = {'Сараа': 'saraa', 'Бат': 'bat', 'Номин': 'nomin', 'Тэмүүлэн': 'temuulen'}  # 고정 인물. 그 밖은 나이·성별 칸을 편 작성 때 정한다
EXTRA = {'점원': 'woman_y', '택시 기사': 'man_m', '식당 주인': 'woman_m'}
KEEP = re.compile(r"[^А-Яа-яЁёӨөҮү0-9{}_a-z ,.!?…-]")

def spoken(s): return re.sub(r'\s+', ' ', KEEP.sub('', s)).strip()

def plan(e):
    cast = {k: CAST.get(v) or EXTRA.get(v) or 'man_y' for k, v in e['speakers'].items() if k != 'A'}
    turns = {}
    for t in e['turns']:
        segs = []
        for g in t.get('segs') or [[t['emotion'], t['tl']]]:
            r = spoken(g[1])
            if not r: continue
            if re.search(r'[가-힣]', g[1]): print(f"{e['id']} {t['num']}턴: 한글 인용은 음성에서 빠짐 — 생성 때 확인")
            segs.append([g[0], g[1]] if r == g[1].strip() else [g[0], g[1], r])
        turns[str(t['num'])] = {'segs': segs}
    return {'ep': e['id'], 'cast': cast, 'turns': turns}

want = set(sys.argv[1:])
n = 0
OUT.mkdir(parents=True, exist_ok=True)
for f in sorted(glob.glob(str(ROOT / 'app/assets/data/dialogues/R*/*/*.json'))):
    e = json.load(open(f, encoding='utf-8'))
    if want and e['id'] not in want: continue
    json.dump(plan(e), open(OUT / f"{e['id']}.json", 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    n += 1
print(n, '편 →', OUT)
