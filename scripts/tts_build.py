# -*- coding: utf-8 -*-
"""모든 문장(travel/*.json) → Azure mn-MN 사전 합성 + manifest 생성.

성별 정보 없음 → 전부 여성(Yesui). 결과:
  app/assets/audio/<id>.mp3
  app/assets/audio/manifest.json   { "<clean mn>": "audio/<id>.mp3" }

manifest key 는 tts_service._clean(text) 과 동일 규칙으로 정규화한 키릴 원문.
앱은 speak(text) 시 manifest 에 있으면 번들 mp3 재생, 없으면 런타임 Azure 폴백.

usage: python scripts/tts_build.py [--resume]
키: AZURE_SPEECH_KEY env, 없으면 talkverse-learning/.env 에서 읽음.
"""
import argparse
import glob
import hashlib
import json
import os
import re
import sys
import time
from pathlib import Path

import requests

ROOT = Path(__file__).resolve().parent.parent
TRAVEL = ROOT / "app" / "assets" / "data" / "travel"
OUT = ROOT / "app" / "assets" / "audio"
ENV = Path("C:/Users/Johnjeon/OneDrive/Archive/PROJECT/talkverse-learning/.env")
VOICE = "mn-MN-YesuiNeural"  # 여성 (성별 없음 → 기본)
REGION_DEFAULT = "koreacentral"
BUCKET = "tts"  # Supabase Storage 공개 버킷


def _env(name):
    v = os.environ.get(name)
    if not v and ENV.exists():
        for line in ENV.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if line.startswith(f"{name}="):
                v = line.split("=", 1)[1].strip()
                break
    return v


def public_base():
    """manifest 의 mp3 공개 URL prefix. SUPABASE_URL 없으면 로컬 에셋 경로로 폴백."""
    url = (_env("SUPABASE_URL") or "").rstrip("/")
    return f"{url}/storage/v1/object/public/{BUCKET}" if url else "audio"


def load_key():
    key = os.environ.get("AZURE_SPEECH_KEY")
    region = os.environ.get("AZURE_SPEECH_REGION")
    if (not key or not region) and ENV.exists():
        for line in ENV.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if "=" not in line or line.startswith("#"):
                continue
            k, v = line.split("=", 1)
            k, v = k.strip(), v.strip()
            if k == "AZURE_SPEECH_KEY" and not key:
                key = v
            elif k == "AZURE_SPEECH_REGION" and not region:
                region = v
    return key, (region or REGION_DEFAULT)


def clean(t: str) -> str:
    """tts_service._clean 과 동일 규칙."""
    t = re.sub(r"\((?:원형)?[^)]*\)", "", t)
    t = re.sub(r"[\[\]{}]", "", t)
    return t.replace("__", "").replace("́", "").strip()


DATA = ROOT / "app" / "lib" / "data"
CLIFF = ROOT / "app" / "assets" / "data" / "cliff"
# Tok('어간', infl: '어미', ...) → surface = 어간+어미
_TOK = re.compile(r"Tok\(\s*'([^']*)'(?:[^)]*?infl:\s*'([^']*)')?")


def _turn_texts(path, splitter):
    """dart 파일에서 ChatTurn(/Sentence([ 단위로 Tok surface 들을 join → 발화 문자열.
    세그먼트(다음 splitter 전까지) 안의 Tok 은 모두 그 발화의 토큰이다."""
    out = []
    if not path.exists():
        return out
    for seg in path.read_text(encoding="utf-8").split(splitter)[1:]:
        words = [s + i for s, i in _TOK.findall(seg)]
        if words:
            out.append(" ".join(words))
    return out


def collect_texts():
    seen, items = set(), []

    def add(c):
        c = clean(c)
        if c and c not in seen:
            seen.add(c)
            items.append(c)

    # 1) travel 문장
    for f in sorted(glob.glob(str(TRAVEL / "*.json"))):
        for e in json.loads(Path(f).read_text(encoding="utf-8")):
            add(e.get("mn", ""))
    # 2) 대화 턴 (l2_dialogues) · 커리큘럼 문장
    for t in _turn_texts(DATA / "l2_dialogues.dart", "ChatTurn("):
        add(t)
    for t in _turn_texts(DATA / "curriculum_sentences.dart", "Sentence(["):
        add(t)
    # 3) 단어: content_words(mn) · cliff lemma · 알파벳 글자
    cw = DATA / "content_words.dart"
    if cw.exists():
        for m in re.findall(r"ContentWord\(\s*'([^']+)'", cw.read_text(encoding="utf-8")):
            add(m)
    for f in sorted(glob.glob(str(CLIFF / "*.tsv"))):
        for line in Path(f).read_text(encoding="utf-8").splitlines()[1:]:
            cols = line.split("\t")
            if len(cols) > 1:
                add(cols[1])
    alpha = DATA / "cyrillic_alphabet_data.dart"
    if alpha.exists():
        for low in re.findall(r"lower:\s*'([^']+)'", alpha.read_text(encoding="utf-8")):
            add(low)
    return items


def synth(text, key, region):
    ssml = (f'<speak version="1.0" xml:lang="mn-MN"><voice name="{VOICE}">'
            f'{text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")}'
            f'</voice></speak>')
    r = requests.post(
        f"https://{region}.tts.speech.microsoft.com/cognitiveservices/v1",
        headers={"Ocp-Apim-Subscription-Key": key,
                 "Content-Type": "application/ssml+xml",
                 "X-Microsoft-OutputFormat": "audio-24khz-48kbitrate-mono-mp3",
                 "User-Agent": "mn-app-tts"},
        data=ssml.encode("utf-8"), timeout=30)
    r.raise_for_status()
    return r.content


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--resume", action="store_true", help="기존 mp3 건너뜀")
    ap.add_argument("--limit", type=int, default=0)
    args = ap.parse_args()

    key, region = load_key()
    if not key:
        print("ERROR: AZURE_SPEECH_KEY 없음", file=sys.stderr)
        sys.exit(1)

    OUT.mkdir(parents=True, exist_ok=True)
    texts = collect_texts()
    if args.limit:
        texts = texts[: args.limit]
    base = public_base()
    print(f"문장 {len(texts)}개 | voice={VOICE} | region={region} | manifest base={base}")

    manifest, done, skip, fail = {}, 0, 0, 0
    for i, text in enumerate(texts, 1):
        fid = hashlib.md5(text.encode("utf-8")).hexdigest()[:12]
        fpath = OUT / f"{fid}.mp3"
        manifest[text] = f"{base}/{fid}.mp3"  # 공개 URL (SUPABASE_URL 있으면)
        if args.resume and fpath.exists() and fpath.stat().st_size > 1000:
            skip += 1
            continue
        try:
            fpath.write_bytes(synth(text, key, region))
            done += 1
            if i <= 6 or i % 50 == 0:
                safe = text[:38].encode("ascii", "replace").decode()
                print(f"  [{i:3d}/{len(texts)}] {fpath.stat().st_size // 1024:3d}KB  {safe}")
        except Exception as e:
            fail += 1
            print(f"  [{i:3d}] FAIL {e}")
        time.sleep(0.04)

    (OUT / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"\nDONE {done}, SKIP {skip}, FAIL {fail} | manifest {len(manifest)} entries")


if __name__ == "__main__":
    main()
