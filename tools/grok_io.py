#!/usr/bin/env python3
"""회화 편 JSON ↔ Grok 원고(헝가리어앱 형식, 2026-11-09).
  python3 tools/grok_io.py export <편id>...   → data/review/grok/src/<id>.txt
  python3 tools/grok_io.py import <편id>...   → data/review/grok/out/<id>.md 의 코드 블록을 편 JSON 에 반영
원고 한 줄 = `화자 | 몽골어 | 한국어 | note | emotion=감정(+감정…)`. 감정이 여러 개면 문장 수와 맞을 때만 segs 로 나눈다.
반영 뒤에는 `python3 tools/check_dialogues.py --fix-rd <파일>` 로 독음을 다시 만들고 검사한다."""
import datetime, glob, json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DLG = ROOT / 'app/assets/data/dialogues'
SRC = ROOT / 'data/review/grok/src'
OUT = ROOT / 'data/review/grok/out'


def path_of(eid):
    hit = glob.glob(str(DLG / 'R*' / '*' / f'{eid}.json'))
    if not hit:
        raise SystemExit(f'편 없음: {eid}')
    return pathlib.Path(hit[0])


def export(eid):
    e = json.load(open(path_of(eid), encoding='utf-8'))
    head = [f"=== {e['id']}", f"kind: {e['kind']}", f"title: {e['title']}", f"emoji: {e.get('emoji', '')}", f"scene: {e['scene']}"]
    head += [f"{k.lower()}: {v}" for k, v in e['speakers'].items() if k != 'A']
    head += [f"register: {e.get('register', '')}", f"twist: {e['twist']} {e['twist_type']}",
             f"purpose: {' '.join(e.get('purpose', []))}", f"goal: {e.get('goal', '')}",
             f"expressions: {'; '.join(e.get('expressions', []))}"]
    rows = []
    for t in e['turns']:
        emo = '+'.join(g[0] for g in t['segs']) if t.get('segs') else t.get('emotion', 'neutral')
        rows.append(' | '.join([t['speaker'], t['tl'], t['ko'], t.get('note') or '', f'emotion={emo}']))
    SRC.mkdir(parents=True, exist_ok=True)
    (SRC / f'{eid}.txt').write_text('\n'.join(head + rows) + '\n', encoding='utf-8')


def sentences(s):
    return [x for x in re.split(r'(?<=[.!?…])\s+', s.strip()) if x]


def do_import(eid):
    raw = (OUT / f'{eid}.md').read_text(encoding='utf-8')
    m = re.search(r'```[a-z]*\n(.*?)```', raw, re.S)
    body = m.group(1) if m else raw
    lines = [l.strip() for l in body.splitlines() if l.strip()]
    head = {}
    rows = []
    for l in lines:
        if l.startswith('==='):
            continue
        if re.match(r'^[A-D] \|', l):
            rows.append([c.strip() for c in l.split('|')])
        elif ':' in l:
            k, v = l.split(':', 1)
            head[k.strip().lower()] = v.strip()
    p = path_of(eid)
    e = json.load(open(p, encoding='utf-8'))
    if len(rows) != len(e['turns']):
        raise SystemExit(f'{eid}: 줄 수 다름 {len(rows)} ≠ {len(e["turns"])} — 반영 안 함')
    for t, r in zip(e['turns'], rows):
        if r[0] != t['speaker']:
            raise SystemExit(f'{eid}: {t["num"]}턴 화자 다름 — 반영 안 함')
        t['tl'], t['ko'] = r[1], r[2]
        t['note'] = r[3] if len(r) > 3 else t.get('note', '')
        emo = (r[4].split('=', 1)[1] if len(r) > 4 and '=' in r[4] else t.get('emotion', 'neutral')).strip()
        parts = [x.strip() for x in emo.split('+') if x.strip()]
        t.pop('segs', None)
        ss = sentences(t['tl'])
        if len(parts) > 1 and len(parts) == len(ss):
            t['segs'] = [[a, b] for a, b in zip(parts, ss)]
            t['emotion'] = parts[-1]
        else:
            t['emotion'] = parts[0] if parts else 'neutral'
        t['rd'] = ''
    for k in ('title', 'scene'):
        if head.get(k):
            e[k] = head[k]
    e.setdefault('review', {})['grok_rewrite'] = f'{datetime.date.today()} Grok 전문가 재작성 반영(data/review/grok/out/{eid}.md)'
    json.dump(e, open(p, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    open(p, 'a').write('\n')
    print('반영', eid)


if __name__ == '__main__':
    cmd, ids = sys.argv[1], sys.argv[2:]
    for i in ids:
        export(i) if cmd == 'export' else do_import(i)
