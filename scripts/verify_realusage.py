"""실사용 빈도 검수 — discover/mn 기준 (lang_mn_opus_cleaned_top5000.csv).

교과서/번역체 어휘 vs 실제 자주 쓰는 어휘를 빈도 순위(rank)로 판정.
- top 2000 = 일상 핵심, top 5000 = 흔함, 그 밖 = 희귀(교과서/번역체 의심)
- 굴절형은 stem-fuzzy 로 흡수.

usage: python verify_realusage.py [--json ...survival_200.json] [--core 2000]
출력: scripts/_realusage_report.md
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
REF = ROOT / "db" / "corpus" / "lang_mn_opus_cleaned_top5000.csv"
CYR = re.compile(r"[а-яёөүА-ЯЁӨҮ]+")


def toks(s):
    return [m.group(0).lower() for m in CYR.finditer(s)]


def strip_markup(s):
    s = re.sub(r"\((?:원형)?[^)]*\)", "", s)
    for ch in "[]{}":
        s = s.replace(ch, "")
    return s.replace("__", "")


def load_ranks():
    rank = {}
    for line in REF.read_text(encoding="utf-8-sig").splitlines()[1:]:
        p = line.split(",")
        if len(p) >= 2:
            try:
                rank[p[1].strip().lower()] = int(p[0])
            except ValueError:
                pass
    return rank


def best_rank(w, rank, cap=5000):
    if w in rank:
        return rank[w]
    best = None
    for k in range(1, 5):
        if len(w) - k >= 3 and w[:-k] in rank:
            best = min(best or 10**9, rank[w[:-k]])
    return best


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", default="app/assets/data/dialogues/survival_200.json")
    ap.add_argument("--core", type=int, default=2000)
    args = ap.parse_args()

    rank = load_ranks()
    print(f"실사용 기준 어휘: {len(rank):,} (opus_cleaned top5000)")
    data = json.loads((ROOT / args.json).read_text(encoding="utf-8"))
    turns = data["turns"]

    rows = []
    for t in turns:
        w = toks(strip_markup(t["mn"]))
        if not w:
            continue
        ranks = [best_rank(x, rank) for x in w]
        rare = [w[i] for i, r in enumerate(ranks) if r is None]          # top5000 밖
        noncore = [w[i] for i, r in enumerate(ranks) if r is None or r > args.core]
        core_ratio = 1 - len(noncore) / len(w)
        rows.append((core_ratio, len(rare), rare, t))

    rows.sort(key=lambda x: (x[0], -x[1]))
    avg_core = sum(r[0] for r in rows) / len(rows) if rows else 0
    rare_flag = [r for r in rows if r[1] > 0]

    lines = [
        "# 생존 200 실사용 빈도 검수 (discover/mn 기준)\n",
        f"기준: lang_mn_opus_cleaned_top5000.csv · core=top{args.core}\n",
        f"\n## 요약\n- 평균 일상핵심(top{args.core}) 어휘 비율: **{avg_core*100:.1f}%**",
        f"- top5000 밖(희귀/교과서 의심) 단어 포함 문장: **{len(rare_flag)}**\n",
        "\n## 희귀 어휘 포함 문장 (실사용 낮은 순)\n",
    ]
    for cr, nrare, rare, t in rows:
        if nrare == 0:
            continue
        lines.append(f"- **#{t['num']}**[{t['cat']}] core {cr*100:.0f}% · 희귀 {rare}")
        lines.append(f"  - {t['ko']}")
    rep = SCR / "_realusage_report.md"
    rep.write_text("\n".join(lines), encoding="utf-8")
    print(f"평균 일상핵심 비율 {avg_core*100:.1f}% · 희귀어 문장 {len(rare_flag)}")
    print(f"→ {rep}")


if __name__ == "__main__":
    main()
