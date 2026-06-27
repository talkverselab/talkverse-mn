#!/usr/bin/env bash
# app/assets/audio/*.mp3 → Supabase Storage 공개 버킷 'tts' 업로드.
# 키: env SUPABASE_SERVICE_KEY (service_role) + SUPABASE_URL. doppler run 권장:
#   doppler run -- bash scripts/tts_upload.sh
# 한국 ISP(kornet) DNS 가 supabase 서브도메인을 NXDOMAIN 처리 → 공용 DNS IP 로 --resolve 우회.
set -euo pipefail

KEY="${SUPABASE_SERVICE_KEY:?SUPABASE_SERVICE_KEY 필요(service_role)}"
URL="${SUPABASE_URL:?SUPABASE_URL 필요}"
BUCKET="tts"
HOST="$(echo "$URL" | sed -E 's#https?://([^/]+).*#\1#')"
# 공용 DNS 로 호스트 IP 해석 (kornet NXDOMAIN 우회). 실패 시 시스템 DNS 사용.
IP="$(nslookup "$HOST" 8.8.8.8 2>/dev/null | awk '/^Address: /{a=$2} END{print a}')"
RESOLVE=(); [ -n "${IP:-}" ] && RESOLVE=(--resolve "$HOST:443:$IP")
echo "host=$HOST ip=${IP:-system-dns} bucket=$BUCKET"

# 버킷 없으면 생성(공개)
curl -s "${RESOLVE[@]}" -X POST -H "apikey: $KEY" -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d "{\"id\":\"$BUCKET\",\"name\":\"$BUCKET\",\"public\":true,\"allowed_mime_types\":[\"audio/mpeg\"]}" \
  "https://$HOST/storage/v1/bucket" >/dev/null || true

n=0; ok=0; fail=0; total=$(ls app/assets/audio/*.mp3 2>/dev/null | wc -l)
for f in app/assets/audio/*.mp3; do
  n=$((n+1)); base="$(basename "$f")"
  code=$(curl -s "${RESOLVE[@]}" -o /dev/null -w "%{http_code}" -X POST \
    -H "apikey: $KEY" -H "Authorization: Bearer $KEY" -H "x-upsert: true" \
    -H "Content-Type: audio/mpeg" --data-binary @"$f" \
    "https://$HOST/storage/v1/object/$BUCKET/$base")
  if [ "$code" = "200" ]; then ok=$((ok+1)); else fail=$((fail+1)); echo "  FAIL $base HTTP $code"; fi
  [ $((n%60)) -eq 0 ] && echo "  ...$n/$total (ok=$ok)"
done
echo "DONE ok=$ok fail=$fail / $total"
