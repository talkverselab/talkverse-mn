#!/usr/bin/env python3
"""몽골어 회화 편 검사기(2026-11-07).
  python3 tools/check_dialogues.py [--fix-rd] [--report] [파일...]   파일이 없으면 R 구조 전체
검사: 턴 수(R1 6~8 · R2 8~12 · R3 12~16)·한 턴 낱말 수·1단어 턴·표현 풀 ≥2·반전·twist_type·독음·한국어·expressions 가 대사에 있는지.
--fix-rd: scripts/normalize_pron.py 로 rd 를 채운다(결정론, 손으로 고치지 않는다).
--report: twist_type·주제·레벨 분포, 카오스 비율, 단어 목록 안 비율(경고용 통계 — 절벽 R1 이 49어라 구간 어휘는 막지 않는다)."""
import argparse, collections, csv, glob, json, pathlib, re, sys
ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / 'scripts'))
from normalize_pron import transliterate
DLG = ROOT / 'app/assets/data/dialogues'
TURNS = {'R1': (6, 8), 'R2': (8, 12), 'R3': (12, 16)}
MAXW = {'R1': 7, 'R2': 9, 'R3': 12}
TWISTS = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
WORD = re.compile(r"[А-Яа-яЁёӨөҮү-]+")

def words(s): return WORD.findall(re.sub(r'\{[a-z_]+\}', '', s))
def fold(s): return re.sub(r'\s+', ' ', re.sub(r'[?!.,…]', '', s.lower())).strip()
def pool():
    return [fold(r['expr']) for r in csv.DictReader(open(ROOT / 'data/expressions/mn_top_expressions.csv', encoding='utf-8'))]
def wordlist():
    return {r['word'].lower() for r in csv.DictReader(open(ROOT / 'app/assets/data/freq/mn_words.csv', encoding='utf-8-sig'))}

def check(e, P):
    errs, reg = [], e['region']
    lo, hi = TURNS[reg]
    T = e['turns']
    if not lo <= len(T) <= hi: errs.append(f'턴 수 {len(T)}')
    if e.get('twist_type') not in TWISTS: errs.append('twist_type 없음')
    if not isinstance(e.get('twist'), int) or not 1 <= e['twist'] <= len(T): errs.append('twist 턴 번호')
    text = ' | '.join(fold(t['tl']) for t in T)
    hits = [x for x in P if re.search(rf'(?<![а-яёөү]){re.escape(x)}(?![а-яёөү])', text)]
    if len(hits) < 2: errs.append(f'표현 풀 {len(hits)}개')
    for x in e.get('expressions', []):
        if fold(x) not in text: errs.append(f'expressions 없음: {x}')
    for i, t in enumerate(T, 1):
        if t['num'] != i: errs.append(f'{i}턴 번호')
        if t['speaker'] not in e['speakers']: errs.append(f'{i}턴 화자')
        n = len(words(t['tl']))
        if n > MAXW[reg]: errs.append(f'{i}턴 낱말 {n}')
        if n == 1 and i != e.get('twist') and i != len(T) and fold(t['tl']) not in P: errs.append(f'{i}턴 1단어')
        if not t.get('ko'): errs.append(f'{i}턴 한국어 없음')
        if not t.get('rd'): errs.append(f'{i}턴 독음 없음')
    return errs

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('files', nargs='*'); ap.add_argument('--fix-rd', action='store_true'); ap.add_argument('--report', action='store_true')
    a = ap.parse_args()
    files = a.files or sorted(glob.glob(str(DLG / 'R*/*/*.json')))
    P, W = pool(), wordlist()
    bad, stats, cov = 0, collections.Counter(), [0, 0]
    for f in files:
        e = json.load(open(f, encoding='utf-8'))
        if a.fix_rd:
            for t in e['turns']:
                t['rd'] = re.sub(r'\s+', ' ', transliterate(re.sub(r'\{name\}', '@', t['tl']))).replace('@', '{name}').strip()
            json.dump(e, open(f, 'w', encoding='utf-8'), ensure_ascii=False, indent=1); open(f, 'a').write('\n')
        for m in check(e, P):
            print(f"{e['id']}: {m}"); bad += 1
        stats[e.get('twist_type')] += 1; stats[e['region']] += 1; stats[e['island']] += 1
        for t in e['turns']:
            for w in words(t['tl']):
                cov[1] += 1; cov[0] += w.lower() in W
    print(f'{len(files)}편 · 오류 {bad}')
    if a.report:
        print(dict(stats)); n = len(files) or 1
        print(f"카오스 {stats['chaos']}/{n} = {stats['chaos'] * 100 // n}% · 표제어 그대로 일치 {cov[0] * 100 // max(cov[1], 1)}%")
    return 1 if bad else 0
sys.exit(main())
