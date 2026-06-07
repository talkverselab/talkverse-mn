"""Azure TTS — synthesize mn-MN sentences to MP3.

usage:
  python tts_azure.py --voice female              # L1 (turn_NNN.mp3)
  python tts_azure.py --set survival --voice female   # survival_200 (sv_NNN.mp3)
  python tts_azure.py --set survival --voice male --resume
마크업([ ]{ }__()) 은 합성 전 제거됨.
"""
import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

import requests

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

ROOT = Path(__file__).resolve().parent.parent
DIAL = ROOT / "app" / "assets" / "data" / "dialogues"
AUDIO = ROOT / "app" / "assets" / "audio"

# 합성 세트: json 경로, 출력 루트, 파일 prefix
SETS = {
    "l1": (DIAL / "L1.json", AUDIO, "turn_"),
    "survival": (DIAL / "survival_200.json", AUDIO / "survival", "sv_"),
}

VOICES = {
    "female": "mn-MN-YesuiNeural",
    "male": "mn-MN-BataaNeural",
}

# 학습용 마크업 제거 ([оос]→оос, {даг}→даг, __аар__(원형 X)→аар)
def clean(mn: str) -> str:
    mn = re.sub(r"\((?:원형)?[^)]*\)", "", mn)
    for ch in "[]{}":
        mn = mn.replace(ch, "")
    return mn.replace("__", "").strip()

ENV_PATH = Path("C:/Users/Administrator/Downloads/talkverse-learning/talkverse-learning/.env")


def load_env():
    env = {}
    if ENV_PATH.exists():
        for line in ENV_PATH.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip()
    # env vars override
    for k in ("AZURE_SPEECH_KEY", "AZURE_SPEECH_REGION"):
        if os.environ.get(k):
            env[k] = os.environ[k]
    return env


def synth(text: str, voice: str, key: str, region: str) -> bytes:
    endpoint = f"https://{region}.tts.speech.microsoft.com/cognitiveservices/v1"
    ssml = (
        f'<speak version="1.0" xml:lang="mn-MN">'
        f'<voice name="{voice}">{text}</voice></speak>'
    )
    headers = {
        "Ocp-Apim-Subscription-Key": key,
        "Content-Type": "application/ssml+xml",
        "X-Microsoft-OutputFormat": "audio-24khz-48kbitrate-mono-mp3",
        "User-Agent": "mn-app-tts",
    }
    r = requests.post(endpoint, headers=headers, data=ssml.encode("utf-8"), timeout=30)
    r.raise_for_status()
    return r.content


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", choices=list(SETS), default="l1")
    ap.add_argument("--voice", choices=list(VOICES), default="female")
    ap.add_argument("--resume", action="store_true", help="skip existing mp3")
    ap.add_argument("--limit", type=int, default=0, help="only first N turns")
    args = ap.parse_args()

    env = load_env()
    key = env.get("AZURE_SPEECH_KEY")
    region = env.get("AZURE_SPEECH_REGION", "koreacentral")
    if not key:
        print("ERROR: AZURE_SPEECH_KEY missing", file=sys.stderr)
        sys.exit(1)

    json_path, out_root, prefix = SETS[args.set]
    voice = VOICES[args.voice]
    out_dir = out_root / args.voice
    out_dir.mkdir(parents=True, exist_ok=True)

    data = json.loads(json_path.read_text(encoding="utf-8"))
    turns = data["turns"]
    if args.limit:
        turns = turns[: args.limit]

    print(f"Set: {args.set} | Voice: {voice} | Out: {out_dir}")
    print(f"Turns: {len(turns)}")

    fail = 0
    done = 0
    skip = 0
    for t in turns:
        num = t["num"]
        text = clean(t["mn"])
        fname = out_dir / f"{prefix}{num:03d}.mp3"
        if args.resume and fname.exists() and fname.stat().st_size > 1000:
            skip += 1
            continue
        try:
            audio = synth(text, voice, key, region)
            fname.write_bytes(audio)
            done += 1
            size_kb = len(audio) // 1024
            safe = text[:40].encode("ascii", errors="replace").decode("ascii")
            print(f"  [{num:3d}/{len(turns)}] {size_kb:3d}KB  {safe}")
        except requests.HTTPError as e:
            fail += 1
            print(f"  [{num:3d}] HTTP {e.response.status_code}: {e.response.text[:120]}")
        except Exception as e:
            fail += 1
            print(f"  [{num:3d}] ERR: {e}")
        time.sleep(0.05)  # ~20 req/s ceiling

    print(f"\nDONE: {done}, SKIP: {skip}, FAIL: {fail}")


if __name__ == "__main__":
    main()
