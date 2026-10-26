# Supabase → Cloudflare 이관 — 몽골어앱 조사 (2026-10-26)

지침: `~/cloudflare-migration/GUIDE.md` · `LANG_APPS_TASK.md`, 설계 기준은 태국어앱 `docs/CLOUDFLARE_MIGRATION.md` §2.

## 결론 — 앱은 Supabase 를 쓰지 않는다

- **앱 실행 중 Supabase 호출 없음.** `pubspec.yaml` 에 `supabase_flutter` 없음, 로그인 없음, 표 없음, RPC 없음.
- 음성은 **앱에 들어 있는 mp3**(`app/assets/audio/`, 578개, 7.4MB)를 재생한다. `manifest.json` 의 값이 전부 `audio/<해시>.mp3`(번들 경로)이고 `http` 주소는 0건.
  `tts_service.dart` 107행 주석("Supabase 공개 mp3 URL")은 옛 설명일 뿐이다.
- 그래서 **Cloudflare 로 옮길 것도, 앱 코드를 바꿀 것도 없다.** `talkverse-db`·`talkverse-accounts` 에 더할 표도 없음.
  (나중에 로그인·학습 기록 동기화를 넣으면 그때 태국어 설계 §2 를 따른다.)

## Supabase 에 남아 있는 것 — 공용 버킷 `tts`(공개)

| 위치 | 파일 | 용량 | 올린 날 | 정체 |
|---|---|---|---|---|
| 버킷 맨 위(폴더 없음) | 578 | 6.2 MB | 2026-06-27 | **지금 앱 번들과 똑같은 파일**(파일 이름 목록 SHA-1 일치 확인) — 개발 도구 `scripts/tts_upload.sh` 가 올린 사본 |
| `mn/` | 1,546 | 24.5 MB | 2026-04-26 | 재구축(2026-09-11) 이전 몽골어 음성. 이 repo·`_legacy/mn` 코드 어디에서도 이 주소를 읽지 않음 |
| `id/` | 1,498 | 24.9 MB | 2026-04-26 | **인도네시아어앱 것** — 이 앱 몫 아님(인도네시아어 세션이 판단) |

버킷 합계 3,622개 · 55.6 MB. 조회는 `storage.objects` SELECT 만 했다.

## 할 일

- **R2 로 옮길 필요 없음** — 앱이 번들 파일로 오프라인 재생하고, 원본은 이 repo 에 있다. 공개 주소가 필요해지면 그때 R2(`talkverse-files` 의 `tts/mn/` 등) + 사용자 커스텀 도메인.
- 개발 도구 정리(대기, 앱 코드 아님): `scripts/tts_upload.sh`(Supabase 업로드)와 `scripts/tts_build.py` 의 `TTS_REMOTE=1` 분기는 Supabase 를 가리킨다. 다시 쓸 일이 생기면 R2 업로드로 바꾼다 — 지금은 손대지 않음.
- **삭제는 사용자가 실행**(세션은 지우지 않음): 버킷 `tts` 의 맨 위 578개(6.2 MB) + `mn/` 1,546개(24.5 MB) = 몽골어 몫 2,124개 · 30.7 MB. 지워도 앱 동작에는 영향 없음. `id/` 는 인도네시아어 세션 확인 뒤.

## 대기

- 없음(요금제·402 제한 해제와 무관 — 옮길 데이터가 없다). Supabase 버킷 삭제만 사용자 몫.
