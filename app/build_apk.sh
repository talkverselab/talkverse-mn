#!/usr/bin/env bash
# Azure TTS 키를 환경변수로 받아 --dart-define 으로 주입해 릴리스 APK 빌드.
# 사용:  doppler run -- bash build_apk.sh
#   (Doppler 가 AZURE_SPEECH_KEY / REGION / VOICE 를 env 로 주입)
# 키 없이 실행하면 기기 내장 TTS 폴백 빌드가 만들어짐.
set -euo pipefail

KEY="${AZURE_SPEECH_KEY:-}"
REGION="${AZURE_SPEECH_REGION:-koreacentral}"
VOICE="${AZURE_SPEECH_VOICE:-mn-MN-YesuiNeural}"

if [ -z "$KEY" ]; then
  echo "⚠ AZURE_SPEECH_KEY 없음 → 기기 내장 TTS 폴백 빌드"
else
  echo "✓ Azure 키 주입 (len=${#KEY}, region=$REGION, voice=$VOICE)"
fi

flutter build apk --release \
  --dart-define=AZURE_SPEECH_KEY="$KEY" \
  --dart-define=AZURE_SPEECH_REGION="$REGION" \
  --dart-define=AZURE_SPEECH_VOICE="$VOICE"

echo "APK: build/app/outputs/flutter-apk/app-release.apk"
