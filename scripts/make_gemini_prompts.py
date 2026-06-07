"""survival_200.json → 제미나이 검수 프롬프트 5개 (40문장씩) 생성.

각 프롬프트: '검수만 / 문장 수정 금지' 명시 + 검수 갯수(N/40) 출력 요청(완전성 확인).
출력: db/gemini_check/check_1.txt ~ check_5.txt
usage: python make_gemini_prompts.py
"""
import argparse
import json
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "app" / "assets" / "data" / "dialogues" / "survival_200.json"
OUT = ROOT / "db" / "gemini_check"
CHUNK = 40

HEADER = """당신은 몽골어(할흐 방언, 키릴) 원어민 수준 검수자입니다.
아래 몽골어 회화 학습 문장 {n}개를 **검수만** 하세요.

⚠️ 절대 규칙
- **문장을 고치거나 다시 쓰지 마세요. 수정안·대안 제시 금지.**
- 오직 각 문장의 문제 유무만 판정합니다. (틀린 곳을 '지적'만, '교정'은 하지 않음)

검수 항목 (각 문장):
1. 문법·철자·모음조화 정확성
2. 실제 몽골인이 일상 대화/메신저에서 쓰는 자연스러운 표현인가 (교과서체·번역체면 지적)
3. 한국어 뜻(ko)과 의미 일치
4. 한글 발음(pron)이 실제 발음과 맞는가
5. 마크업 적절성: [ ]=조사/기능어, {{ }}=뉘앙스 접사, __형태__(원형 X)=모음조화 변형
6. 회화용 길이 적절성 (너무 길면 지적)

출력 형식 (문장별 한 줄):
#번호 | OK 또는 문제 | (문제일 때만) 항목번호 + 한 줄 사유

★ 마지막에 반드시 출력 (완전성 확인용):
- 검수한 문장 수: N / {n}
- OK: __개  /  문제: __개
- 문제 문장 번호: [ ... ]

────────── 검수 대상 {n}문장 (#{start}–{end}) ──────────
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--nums", default="", help="특정 번호만 재검수 (쉼표 구분). 예: 13,21,25")
    ap.add_argument("--single", action="store_true", help="200문장 전체를 한 파일(check_all.txt)로")
    args = ap.parse_args()

    data = json.loads(SRC.read_text(encoding="utf-8"))
    turns = data["turns"]
    cats = data.get("categories", {})
    OUT.mkdir(parents=True, exist_ok=True)

    def render(t):
        return (f"#{t['num']} [{t['cat']}·{cats.get(t['cat'], t['cat'])}]\n"
                f"  뜻(ko): {t['ko']}\n  몽골어(mn): {t['mn']}\n  발음(pron): {t['pron']}")

    # --single: 전체를 한 파일로 (청크 분할 없음)
    if args.single:
        body = HEADER.format(n=len(turns), start=turns[0]["num"], end=turns[-1]["num"])
        f = OUT / "check_all.txt"
        f.write_text(body + "\n\n" + "\n\n".join(render(t) for t in turns) + "\n", encoding="utf-8")
        print(f"check_all.txt — 전체 {len(turns)}문장 1개 파일\n→ {f}")
        return

    # --nums: 교정 후 특정 문장만 단일 재검수 프롬프트
    if args.nums.strip():
        want = {int(x) for x in args.nums.replace(" ", "").split(",") if x}
        sel = [t for t in turns if t["num"] in want]
        body = HEADER.format(n=len(sel), start=sel[0]["num"], end=sel[-1]["num"])
        body = body.replace("검수 대상", "재검수 대상(교정 후)")
        rows = [f"#{t['num']} [{t['cat']}·{cats.get(t['cat'], t['cat'])}]\n"
                f"  뜻(ko): {t['ko']}\n  몽골어(mn): {t['mn']}\n  발음(pron): {t['pron']}" for t in sel]
        f = OUT / "recheck.txt"
        f.write_text(body + "\n\n" + "\n\n".join(rows) + "\n", encoding="utf-8")
        print(f"recheck.txt — {len(sel)}문장 ({sorted(want)})\n→ {f}")
        return

    n_files = (len(turns) + CHUNK - 1) // CHUNK
    for ci in range(n_files):
        chunk = turns[ci * CHUNK:(ci + 1) * CHUNK]
        if not chunk:
            break
        start, end = chunk[0]["num"], chunk[-1]["num"]
        body = HEADER.format(n=len(chunk), start=start, end=end)
        rows = []
        for t in chunk:
            catname = cats.get(t["cat"], t["cat"])
            rows.append(
                f"#{t['num']} [{t['cat']}·{catname}]\n"
                f"  뜻(ko): {t['ko']}\n"
                f"  몽골어(mn): {t['mn']}\n"
                f"  발음(pron): {t['pron']}"
            )
        text = body + "\n\n" + "\n\n".join(rows) + "\n"
        f = OUT / f"check_{ci + 1}.txt"
        f.write_text(text, encoding="utf-8")
        print(f"check_{ci + 1}.txt — #{start}-{end} ({len(chunk)}문장)")

    print(f"\n총 {n_files}개 프롬프트 → {OUT}")
    print(f"문장 합계: {len(turns)} (각 파일을 제미나이에 붙여넣기)")


if __name__ == "__main__":
    main()
