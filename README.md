# 몽골어유니버스 (mn)

한국어 화자를 위한 몽골어(할흐, 키릴) 학습 앱 — Flutter, Android(+ iOS 준비 중).

- 앱 코드·콘텐츠: `app/` — 규칙과 배포 방법은 **`app/CLAUDE.md`** 가 기준이다.
- 콘텐츠: 회화 · 여행 문장 · 단계별 예문 · 기초 명사 — 모두 자체 제작. 음성은 사전 합성 mp3(`app/assets/audio/`).
- 한글 독음 규칙: `db/notes/mn_ko_transcription.md` (적용 `scripts/normalize_pron.py`).
- 음성 합성: `scripts/tts_build.py`(Azure Speech mn-MN, 키는 환경변수).
- 배포: master 푸시 → GitHub Actions → `latest` 릴리스 → 앱 안 「앱 업데이트」. 무선 설치는 Zealot(`app/tools/zealot_push.sh`).
