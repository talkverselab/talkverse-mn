"""survival_200.json 의 몽골어 토큰을 코퍼스 어형 집합과 대조 → OOV 리포트.

사전: build_corpus.py 실행해 _corpus_wordforms.txt 생성 필요.

usage:
  python verify_sentences.py [--json survival_200.json] [--max-oov 0]

출력: scripts/_verify_report.md + stdout 요약. OOV(코퍼스 미출현) 토큰을
문장별로 나열. 고유명사/외래어는 화이트리스트(_loanwords.txt)로 제외.
"""
import argparse
import json
import re
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

ROOT = Path(__file__).resolve().parent.parent
SCR = Path(__file__).resolve().parent
CYR = re.compile(r"[а-яёөүА-ЯЁӨҮ]+")


def strip_markup(s: str) -> str:
    s = re.sub(r"\(원형[^)]*\)", "", s)   # 모음조화 원형 주석 제거
    s = re.sub(r"\([^)]*\)", "", s)        # 기타 괄호 주석 제거
    for ch in "[]{}":
        s = s.replace(ch, "")
    s = s.replace("__", "")
    return s


def tokenize(text: str):
    return [m.group(0).lower() for m in CYR.finditer(text)]


def load_set(path: Path):
    if not path.exists():
        return set()
    return set(path.read_text(encoding="utf-8").splitlines())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", default="app/assets/data/dialogues/survival_200.json")
    ap.add_argument("--max-oov", type=int, default=0,
                    help="문장당 허용 OOV 수 (초과 시 FLAG)")
    args = ap.parse_args()

    corpus = load_set(SCR / "_corpus_wordforms.txt")
    loan = load_set(SCR / "_loanwords.txt")  # 허용 고유명사/외래어 (소문자)
    if not corpus:
        print("ERROR: _corpus_wordforms.txt 없음. build_corpus.py 먼저 실행.", file=sys.stderr)
        sys.exit(2)

    jpath = ROOT / args.json
    if not jpath.exists():
        print(f"ERROR: {jpath} 없음 (생성 대기 중?)", file=sys.stderr)
        sys.exit(2)

    data = json.loads(jpath.read_text(encoding="utf-8"))
    turns = data.get("turns", [])

    # 굴절형 stem 매칭: 토큰의 끝 1~4글자를 떼어낸 어간이 코퍼스에 있으면 인정
    # (몽골어 격조사/어미 굴절을 흡수 — 예: чамтай → чам, ярьдаг → ярь)
    def attested(w: str) -> bool:
        if w in corpus or w in loan:
            return True
        for k in range(1, 5):
            if len(w) - k >= 3 and w[:-k] in corpus:
                return True
        return False

    by_cat = {}
    flagged = []
    tot_tok = 0
    tot_oov = 0
    lines = ["# 생존 200 검수 리포트\n",
             f"코퍼스 어형: {len(corpus):,} · 외래어 허용: {len(loan)} · stem-fuzzy ON\n"]

    for t in turns:
        cat = t.get("cat", "?")
        toks = tokenize(strip_markup(t.get("mn", "")))
        oov = [w for w in toks if not attested(w)]
        c = by_cat.setdefault(cat, {"n": 0, "tok": 0, "oov": 0})
        c["n"] += 1
        c["tok"] += len(toks)
        c["oov"] += len(oov)
        tot_tok += len(toks)
        tot_oov += len(oov)
        if len(oov) > args.max_oov:
            flagged.append((t.get("num"), cat, oov, t.get("mn", "")))

    cov = 100 * (tot_tok - tot_oov) / tot_tok if tot_tok else 0
    lines.append(f"\n## 요약\n")
    lines.append(f"- 문장: {len(turns)} · 토큰: {tot_tok} · OOV: {tot_oov} · 커버리지: {cov:.1f}%")
    lines.append(f"- FLAG (OOV>{args.max_oov}): {len(flagged)}문장\n")
    lines.append("\n## 카테고리별\n")
    lines.append("| cat | 문장 | 토큰 | OOV | 커버리지 |")
    lines.append("|---|---:|---:|---:|---:|")
    for cat in sorted(by_cat):
        c = by_cat[cat]
        cc = 100 * (c["tok"] - c["oov"]) / c["tok"] if c["tok"] else 0
        lines.append(f"| {cat} | {c['n']} | {c['tok']} | {c['oov']} | {cc:.1f}% |")

    lines.append("\n## FLAG 문장 (검수 우선)\n")
    for num, cat, oov, mn in flagged:
        lines.append(f"- **#{num}** [{cat}] OOV={oov}\n  - `{mn}`")

    report = SCR / "_verify_report.md"
    report.write_text("\n".join(lines), encoding="utf-8")

    print(f"문장 {len(turns)} · 커버리지 {cov:.1f}% · FLAG {len(flagged)}")
    print(f"→ {report}")
    # 커버리지 임계 미달이면 비정상 종료 (루프 판단용)
    sys.exit(0 if cov >= 95.0 and len(flagged) == 0 else 1)


if __name__ == "__main__":
    main()
