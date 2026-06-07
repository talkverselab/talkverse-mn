"""DATA_Raw/languages/mn 에서 검증용 몽골어 어형(wordform) 집합을 빌드.

소스:
- tatoeba_mon_sentences.tsv  (검증된 문장; col3 = text)
- opensubtitles_mn_v2024.txt (구어 회화체; 각 줄 = text)
- unimorph_khk.tsv           (lemma + 굴절형; col0,col1)
- unimorph_khk_segmentations.tsv (col0,col1)

출력:
- scripts/_corpus_wordforms.txt  (정렬된 유니크 어형, 소문자)
- scripts/_corpus_freq.tsv       (어형 \t 출현빈도)  ← 빈도 낮은 어휘 식별용
"""
import re
import sys
from collections import Counter
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

RAW = Path("D:/OneDrive/DATA_Raw/languages/mn")
OUT = Path(__file__).resolve().parent

# 몽골 키릴 (ө=04E9, ү=04AF, ё=0451 포함)
CYR = re.compile(r"[а-яёөүА-ЯЁӨҮ]+")


def tokenize(text: str):
    return [m.group(0).lower() for m in CYR.finditer(text)]


def main():
    freq = Counter()

    # tatoeba: id \t lang \t text
    tat = RAW / "tatoeba_mon_sentences.tsv"
    if tat.exists():
        n = 0
        for line in tat.read_text(encoding="utf-8", errors="replace").splitlines():
            parts = line.split("\t")
            if len(parts) >= 3:
                freq.update(tokenize(parts[2]))
                n += 1
        print(f"tatoeba: {n} sentences")

    # opensubtitles: 각 줄 = text
    osub = RAW / "opensubtitles_mn_v2024.txt"
    if osub.exists():
        n = 0
        for line in osub.read_text(encoding="utf-8", errors="replace").splitlines():
            freq.update(tokenize(line))
            n += 1
        print(f"opensubtitles: {n} lines")

    # unimorph: lemma \t form \t feats
    for fn in ("unimorph_khk.tsv", "unimorph_khk_segmentations.tsv"):
        p = RAW / fn
        if p.exists():
            n = 0
            for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
                parts = line.split("\t")
                for col in parts[:2]:
                    for tok in tokenize(col):
                        freq[tok] += 1
                n += 1
            print(f"{fn}: {n} rows")

    # 출력
    wf = OUT / "_corpus_wordforms.txt"
    wf.write_text("\n".join(sorted(freq)), encoding="utf-8")

    fq = OUT / "_corpus_freq.tsv"
    fq.write_text(
        "\n".join(f"{w}\t{c}" for w, c in freq.most_common()),
        encoding="utf-8",
    )

    print(f"\n유니크 어형: {len(freq):,}")
    print(f"→ {wf}")
    print(f"→ {fq}")


if __name__ == "__main__":
    main()
