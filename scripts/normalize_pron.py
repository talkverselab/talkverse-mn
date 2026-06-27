"""몽골 키릴 → 한글 독음 결정론적 변환기 (db/notes/mn_ko_transcription.md 규칙).

학술 표준: 정윤자·이성규(2010) 음성실험 기반 (о=어, у=오, ө=으, ү=우).
travel JSON 5개의 `pron` 필드를 mn 으로부터 일괄 재생성해 일관성을 보장한다.
usage: python normalize_pron.py            # 미리보기(앞 12개)
       python normalize_pron.py --write     # 실제 기록
규칙 요지: о=어, у=오, ө=으, ү=우, 어말 н=받침ㅇ, л=받침ㄹ, г/к=받침ㄱ, м=받침ㅁ,
          б/п/в=받침ㅂ, д=드 т=트 с=스 р=르 х=흐 ж/з=즈 ц=츠 ч=치 ш/щ=시.
"""
import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TRAVEL = ROOT / "app" / "assets" / "data" / "travel"
FILES = ["arrival.json", "self_intro.json", "ask_out.json",
         "travel_together.json", "romance.json"]

# 중성(모음) → jungseong index  (학술 표준 о=어/у=오/ө=으/ү=우)
JUNG = {
    'а': 0, 'э': 5, 'и': 20, 'о': 4, 'ө': 18, 'у': 8, 'ү': 13,
    'е': 7, 'ё': 12, 'ю': 17, 'я': 2, 'ы': 20, 'й': 20,
}
VOWELS = set(JUNG)

# 초성 index
CHO = {ch: i for i, ch in enumerate(
    ['ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ', 'ㅆ',
     'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'])}
# 종성 index (0 = 없음)
JONG = {'': 0, 'ㄱ': 1, 'ㄴ': 4, 'ㄹ': 8, 'ㅁ': 16, 'ㅂ': 17, 'ㅅ': 19, 'ㅇ': 21}

# 자음: (초성 jamo, 종료처리) — batchim:jong jamo | syl:고정 음절
CONS = {
    'б': ('ㅂ', ('batchim', 'ㅂ')),
    'в': ('ㅂ', ('batchim', 'ㅂ')),
    'г': ('ㄱ', ('batchim', 'ㄱ')),
    'к': ('ㅋ', ('batchim', 'ㄱ')),
    'л': ('ㄹ', ('batchim', 'ㄹ')),
    'м': ('ㅁ', ('batchim', 'ㅁ')),
    'н': ('ㄴ', ('batchim', 'ㅇ')),   # 어말/자음앞 받침 ㅇ
    'п': ('ㅍ', ('batchim', 'ㅂ')),
    'д': ('ㄷ', ('syl', '드')),
    'т': ('ㅌ', ('syl', '트')),
    'с': ('ㅅ', ('syl', '스')),
    'р': ('ㄹ', ('syl', '르')),
    'х': ('ㅎ', ('syl', '흐')),
    'ж': ('ㅈ', ('syl', '즈')),
    'з': ('ㅈ', ('syl', '즈')),
    'ф': ('ㅍ', ('syl', '프')),
    'ц': ('ㅊ', ('syl', '츠')),
    'ч': ('ㅊ', ('syl', '치')),
    'ш': ('ㅅ', ('syl', '시')),
    'щ': ('ㅅ', ('syl', '시')),
}
SILENT = {'ъ', 'ь'}

# 고유명사·외래어 관용 표기 예외 (학술 매핑보다 우선). key=소문자 키릴 core.
EXC = {
    'монгол': '몽골', 'монголд': '몽골드', 'монголоос': '몽골로스',
    'солонгос': '솔롱고스', 'солонгосоос': '솔롱고소스', 'солонгост': '솔롱고스트',
    'сөүл': '서울', 'сөүлээс': '서울에스', 'сөүлд': '서울드',
    'говь': '고비', 'болд': '볼드', 'сараа': '사라', 'мөнх': '뭉흐',
    'кофе': '코페', 'кафе': '카페',
    'улаанбаатар': '울란바토르', 'мин': '민', 'минжүн': '민준',
}

# 어말 단모음 탈락(구어) 대상: 2음절 이상에서 어말 а/э/о/ө 는 떨어짐 (байна 벵, ирнэ 이릉).
DROP_FINAL = {'а', 'э', 'о', 'ө'}


def _compose(cho, jung, jong):
    return chr(0xAC00 + (CHO[cho] * 21 + jung) * 28 + JONG[jong])


def _syllabify(word):
    """한 단어(키릴, 소문자) → 한글."""
    out = []          # 각 항목: list[cho,jung,jong]  또는  str(고정 음절)
    pending = None    # 다음 모음의 초성이 될 자음

    # 폐쇄음 г/к/б/п: 어말은 받침, 자음 앞은 음절(그/크/브/프)로 — 소리 살림.
    MID_SYL = {'г': '그', 'к': '크', 'б': '브', 'п': '프'}

    def attach_final(c, final=False):
        cho, fin = CONS[c]
        kind, val = fin
        if kind == 'batchim' and not final and c in MID_SYL:
            out.append(MID_SYL[c])
        elif kind == 'batchim' and out and isinstance(out[-1], list) and out[-1][2] == '':
            out[-1][2] = val
        elif kind == 'batchim':
            out.append([cho, 18, ''])  # 자음+ㅡ  ※ㅡ=18
        else:
            out.append(val)

    chars = [c for c in word if c not in SILENT]
    # 구어 어말 단모음 탈락: 모음 2개 이상 + 마지막이 а/э/о/ө + 그 앞이
    # '받침 가능 자음 + 모음' 구조일 때만 깔끔히 탈락 (байна 벵, энэ 엥).
    # 자음 뒤(ирнэ 등)는 잔여음이 생겨 제외.
    if (len(chars) >= 3 and chars[-1] in DROP_FINAL
            and sum(1 for ch in chars if ch in VOWELS) >= 2
            and chars[-2] in CONS and CONS[chars[-2]][1][0] == 'batchim'
            and chars[-3] in VOWELS):
        chars = chars[:-1]
    n = len(chars)
    skip_next = False
    for i, c in enumerate(chars):
        if skip_next:
            skip_next = False
            continue
        nxt = chars[i + 1] if i + 1 < n else ''
        if c in VOWELS:
            prev = chars[i - 1] if i > 0 else ''
            # 구어 이중모음 단모음화: ай/эй → 에 (сайн 셍, байна 베나)
            if c in ('а', 'э') and nxt == 'й':
                cho = CONS[pending][0] if pending else 'ㅇ'
                out.append([cho, 5, ''])  # ㅔ
                pending = None
                skip_next = True
                continue
            # 장모음(같은 모음 연속) → 1회로 축약: уу→오, өө→으, ээ→에 …
            if (pending is None and prev in VOWELS and JUNG.get(prev) == JUNG[c]
                    and out and isinstance(out[-1], list) and out[-1][2] == ''
                    and out[-1][1] == JUNG[c]):
                continue
            cho = CONS[pending][0] if pending else 'ㅇ'
            out.append([cho, JUNG[c], ''])
            pending = None
        elif c in CONS:
            if pending is not None:
                attach_final(pending)
                pending = None
            if nxt in VOWELS:
                pending = c
            else:
                attach_final(c, final=(nxt == ''))
        else:
            # 알 수 없는 글자(라틴 등) → 그대로
            if pending is not None:
                attach_final(pending); pending = None
            out.append(c)
    if pending is not None:
        attach_final(pending, final=True)

    res = []
    for s in out:
        if isinstance(s, str):
            res.append(s)
        else:
            cho, jung, jong = s
            res.append(_compose(cho, jung, jong))
    return ''.join(res)


def transliterate(text):
    words = re.split(r'(\s+)', text.lower())
    parts = []
    for w in words:
        if w.strip() == '':
            parts.append(w)
            continue
        core = re.sub(r'[^а-яёөү]', '', w.lower())
        if core in EXC:
            parts.append(EXC[core])
        else:
            parts.append(_syllabify(core) if core else '')
    return ''.join(parts).strip()


# ── dart 토큰 독음 재생성 ──────────────────────────────
# Tok('어간', infl: '어미', stemKo: '...', inflKo: '...') 의 stemKo/inflKo 를
# 각각 어간·어미 키릴에서 재생성. Tok(...) 은 한 줄이라는 전제(현재 데이터 충족).
DART_FILES = [
    ROOT / "app" / "lib" / "data" / "curriculum_sentences.dart",
    ROOT / "app" / "lib" / "data" / "l2_dialogues.dart",
]
_TOK = re.compile(r"Tok\(\s*'([^']*)'")
_INFL = re.compile(r"infl:\s*'([^']*)'")


def rewrite_dart_line(line):
    mt = _TOK.search(line)
    if not mt or 'stemKo:' not in line:
        return line, []
    stem, changes = mt.group(1), []
    mi = _INFL.search(line)

    def _stem(m):
        new = f"stemKo: '{transliterate(stem)}'"
        if m.group(0) != new:
            changes.append((m.group(0), new))
        return new
    line = re.sub(r"stemKo:\s*'[^']*'", _stem, line)
    if mi:
        def _infl(m):
            new = f"inflKo: '{transliterate(mi.group(1))}'"
            if m.group(0) != new:
                changes.append((m.group(0), new))
            return new
        line = re.sub(r"inflKo:\s*'[^']*'", _infl, line)
    return line, changes


def rewrite_darts(write, show):
    shown = 0
    for p in DART_FILES:
        out, n = [], 0
        for line in p.read_text(encoding='utf-8').splitlines(keepends=True):
            new, changes = rewrite_dart_line(line)
            out.append(new)
            for old_s, new_s in changes:
                n += 1
                if show and shown < 16:
                    print(f"  {p.name}: {old_s}  ->  {new_s}")
                    shown += 1
        if write:
            p.write_text(''.join(out), encoding='utf-8')
        print(f"  {p.name}: {n} 토큰 {'기록' if write else '변경예정'}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--write', action='store_true')
    args = ap.parse_args()
    shown = 0
    for fn in FILES:
        p = TRAVEL / fn
        data = json.loads(p.read_text(encoding='utf-8'))
        for e in data:
            new = transliterate(e['mn'])
            if shown < 12:
                print(f"{e['mn']:<34} {e.get('pron',''):<22} -> {new}")
                shown += 1
            e['pron'] = new
        if args.write:
            p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n',
                         encoding='utf-8')
    print(f"\n{'WROTE' if args.write else 'PREVIEW'} — travel {len(FILES)} files")
    print("dart:")
    rewrite_darts(args.write, show=not args.write)


if __name__ == '__main__':
    main()
