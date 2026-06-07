"""몽골 키릴 → 한글 독음 결정론적 변환기 (db/notes/mn_ko_transcription.md 규칙).

travel JSON 5개의 `pron` 필드를 mn 으로부터 일괄 재생성해 일관성을 보장한다.
usage: python normalize_pron.py            # 미리보기(앞 12개)
       python normalize_pron.py --write     # 실제 기록
규칙 요지: ө=어, у=오, ү=우, 어말 н=받침ㅇ, л=받침ㄹ, г/к=받침ㄱ, м=받침ㅁ,
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

# 중성(모음) → jungseong index
JUNG = {
    'а': 0, 'э': 5, 'и': 20, 'о': 8, 'ө': 4, 'у': 8, 'ү': 13,
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
    n = len(chars)
    for i, c in enumerate(chars):
        nxt = chars[i + 1] if i + 1 < n else ''
        if c in VOWELS:
            prev = chars[i - 1] if i > 0 else ''
            # 장모음(같은 모음 연속) → 1회로 축약: уу→오, өө→어, ээ→에 …
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
        core = re.sub(r'[^а-яёөү]', '', w)
        parts.append(_syllabify(core) if core else '')
    return ''.join(parts).strip()


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
    print(f"\n{'WROTE' if args.write else 'PREVIEW'} — {len(FILES)} files")


if __name__ == '__main__':
    main()
