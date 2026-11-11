#!/usr/bin/env python3
"""Gemini 검수를 한 메시지에 3편씩 묶는다(사용자 결정 2026-11-11 — 한도가 메시지 수로 걸려 처리량 3배).
  python3 tools/gemini_bundle.py make <편별 목록.tsv> <묶음 폴더> [-n 3]  → <폴더>/b_<첫편>.txt·bundles.tsv(gemini_batch 용)·map.json
  python3 tools/gemini_bundle.py split <묶음 폴더>                       → 묶음 답을 「### <편id>」 마다 나눠 편별 저장 경로에 쓴다
편별 목록 = 언어 저장소의 프롬프트 도구가 만든 <편 프롬프트>\t<편 답 저장> 줄(답이 이미 있는 편은 빠져 있음).
나눈 조각에 ①~⑤ 가 다 있어야 저장한다 — 잘리거나 빠진 편은 다음 회차 목록에 다시 들어간다."""
import json, os, pathlib, re, sys

HEAD = ('아래 {n}편을 **편마다 따로** 검수해 주세요. 편마다 지침은 같습니다(각 편 머리말 참고).\n'
        '답은 편마다 반드시 `### <편 코드>` 한 줄로 시작하고(코드는 아래 목록 그대로: {codes}), 그 아래에 ①~⑤ 를 모두 쓰세요. 편을 건너뛰거나 합치지 마세요.\n')


def code(save):
    return os.path.basename(save).removesuffix('_gemini.md')


def make(lst, d, n):
    d = pathlib.Path(d); d.mkdir(parents=True, exist_ok=True)
    for f in d.glob('b_*'): f.unlink()
    rows = [l.rstrip('\n').split('\t') for l in open(lst, encoding='utf-8') if l.strip()]
    out, mp = [], {}
    for i in range(0, len(rows), n):
        g = rows[i:i + n]; cs = [code(s) for _, s in g]
        body = HEAD.format(n=len(g), codes=', '.join(cs)) + ''.join(
            f'\n\n===== 편 {k + 1}/{len(g)} · 코드 {c} =====\n' + open(p, encoding='utf-8').read().strip() for k, ((p, s), c) in enumerate(zip(g, cs)))
        bp = d / f'b_{cs[0]}.txt'; ba = d / f'b_{cs[0]}_ans.md'
        bp.write_text(body + '\n', encoding='utf-8'); out.append(f'{bp}\t{ba}'); mp[str(ba)] = [[c, s] for c, (_, s) in zip(cs, g)]
    (d / 'bundles.tsv').write_text('\n'.join(out) + ('\n' if out else ''), encoding='utf-8')
    (d / 'map.json').write_text(json.dumps(mp, ensure_ascii=False, indent=1), encoding='utf-8')
    print(len(rows), '편', len(out), '묶음')


def split(d):
    d = pathlib.Path(d); mp = json.load(open(d / 'map.json', encoding='utf-8')); ok = miss = 0
    for ans, eps in mp.items():
        if not os.path.exists(ans): continue
        t = open(ans, encoding='utf-8').read(); model = t.splitlines()[0] if t.startswith('<!--') else ''
        cs = [c for c, _ in eps]; sec, cur = {}, None
        for line in t.splitlines():  # 화면 글(innerText)에선 ### 가 사라지므로 「코드만 있는 줄」로 나눈다
            k = re.sub(r'[#*\[\]`:\s]|^MY-|편|코드', '', line).removeprefix('MY-')
            if k in cs: cur = k; sec[cur] = []; continue
            if cur: sec[cur].append(line)
        for c, save in eps:
            part = '\n'.join(sec.get(c, [])).strip()
            if part and sum(x in part for x in '①②③④⑤') == 5:
                open(save, 'w', encoding='utf-8').write((model + '\n' if model else '') + f'<!-- 3편 묶음 {os.path.basename(ans)} -->\n' + part + '\n'); ok += 1
            else:
                miss += 1; print('빠짐', c)
        os.rename(ans, ans + '.done')
    print('나눔', ok, '빠짐', miss)


if __name__ == '__main__':
    a = sys.argv[1:]
    if a[0] == 'make':
        make(a[1], a[2], int(a[a.index('-n') + 1]) if '-n' in a else 3)
    else:
        split(a[1])
