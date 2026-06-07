"""문장 '자연스러움'(실제 사용 빈도) 검수 — 단어가 아니라 표현(n-gram) 대조.

OpenSubtitles(구어) + Tatoeba 에서 bigram/trigram 집합을 만들고,
각 생존 문장의 bigram 이 실제로 그 코퍼스에 등장하는 비율(자연스러움 점수)을 계산.
점수 낮음 = 번역체/교과서체 의심 → 재작성 우선.

usage: python verify_phrases.py [--json app/assets/data/dialogues/survival_200.json] [--min 0.5]
출력: scripts/_phrase_report.md + stdout 요약.
"""
import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

ROOT = Path(__file__).resolve().parent.parent
SCR = Path(__file__).resolve().parent
RAW = Path("D:/OneDrive/DATA_Raw/languages/mn")
CYR = re.compile(r"[а-яёөүА-ЯЁӨҮ]+")


def toks(s: str):
    return [m.group(0).lower() for m in CYR.finditer(s)]


def strip_markup(s: str) -> str:
    s = re.sub(r"\((?:원형)?[^)]*\)", "", s)
    for ch in "[]{}":
        s = s.replace(ch, "")
    return s.replace("__", "")


def build_ngrams():
    # ★ Tatoeba/교재 제외 — 실제 구어(OpenSubtitles)만. (사용자 지시 2026-05-21)
    bi = Counter()
    tri = Counter()
    for fn, col in (("opensubtitles_mn_v2024.txt", None),):
        p = RAW / fn
        if not p.exists():
            continue
        for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
            text = line.split("\t")[col] if col is not None and "\t" in line else line
            w = toks(text)
            for i in range(len(w) - 1):
                bi[(w[i], w[i + 1])] += 1
            for i in range(len(w) - 2):
                tri[(w[i], w[i + 1], w[i + 2])] += 1
    return bi, tri


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", default="app/assets/data/dialogues/survival_200.json")
    ap.add_argument("--min", type=float, default=0.5, help="자연스러움 최소 (bigram 등장률)")
    args = ap.parse_args()

    print("n-gram 집합 빌드 중 (opensubtitles + tatoeba)...")
    bi, tri = build_ngrams()
    print(f"bigram {len(bi):,} · trigram {len(tri):,}")

    data = json.loads((ROOT / args.json).read_text(encoding="utf-8"))
    turns = data["turns"]

    CHUNK_CAP = 14  # 매우 긴 문장만 표시 (짧게 강제 X — 자연스러운 길이 허용)
    scored = []
    long_sents = []
    wc_sum = 0
    for t in turns:
        w = toks(strip_markup(t["mn"]))
        wc = len(w)
        wc_sum += wc
        if wc > CHUNK_CAP:
            long_sents.append((wc, t))
        bigrams = [(w[i], w[i + 1]) for i in range(len(w) - 1)]
        if not bigrams:
            continue
        hit = sum(1 for b in bigrams if b in bi)
        trihit = sum(1 for i in range(len(w) - 2) if (w[i], w[i + 1], w[i + 2]) in tri)
        cov = hit / len(bigrams)
        scored.append((cov, trihit, t, hit, len(bigrams)))

    scored.sort(key=lambda x: x[0])
    flagged = [s for s in scored if s[0] < args.min]
    avg = sum(s[0] for s in scored) / len(scored) if scored else 0
    avg_wc = wc_sum / len(turns) if turns else 0
    long_sents.sort(key=lambda x: -x[0])

    lines = ["# 생존 200 자연스러움(표현) + 청크 검수\n",
             f"bigram 사전 {len(bi):,} · trigram {len(tri):,} (opensubtitles+tatoeba)\n",
             f"\n## 요약\n- 문장 {len(scored)} · 평균 bigram 등장률 **{avg*100:.1f}%**",
             f"- 평균 어절수 **{avg_wc:.1f}** (청크 캡 {CHUNK_CAP}, 목표 4~7)",
             f"- 어절 초과(>{CHUNK_CAP}) 문장: **{len(long_sents)}**",
             f"- 번역체 의심 (bigram<{args.min:.0%}): **{len(flagged)}문장**\n",
             "\n## 어절 초과 문장 — 단축 우선 (긴 순)\n"]
    for wc, t in long_sents:
        lines.append(f"- **#{t['num']}** [{t['cat']}] **{wc}어절** · {t['ko']}")
        lines.append(f"  - `{t['mn']}`")
    lines.append("\n## 번역체 의심 — 재작성 우선 (낮은 순)\n")
    for cov, trihit, t, hit, nb in flagged:
        lines.append(f"- **#{t['num']}** [{t['cat']}] bigram {hit}/{nb}={cov*100:.0f}% · tri {trihit}")
        lines.append(f"  - {t['ko']}")
        lines.append(f"  - `{t['mn']}`")

    rep = SCR / "_phrase_report.md"
    rep.write_text("\n".join(lines), encoding="utf-8")
    print(f"\n평균 bigram 등장률 {avg*100:.1f}% · 번역체 의심 {len(flagged)}문장")
    print(f"→ {rep}")


if __name__ == "__main__":
    main()
