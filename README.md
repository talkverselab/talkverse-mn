# 몽골어유니버스 (mn)

> 몽골어 학습 앱 (한국 화자용) — Flutter 단일 앱
> 시작: 2026-05-17 · git local-only
> 기술명: `mn_app` · 디렉토리: `D:/OneDrive/talkverse/mn/`

---

## 한 줄 정리

한국 화자 → 몽골어. **Flutter** 단일 앱. **git local-only** (GitHub X). 옛 Discover 룸 콘텐츠 재사용 (단국대 표준 + 부사 30 hook 기반 200 문장 + Azure TTS 합성 mn-MN).

---

## 폴더 구조

```
mn/
├── app/                              ← Flutter 앱 (자족, 모든 콘텐츠 + audio 포함)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/theme.dart
│   │   ├── data/
│   │   │   ├── dialogue_models.dart
│   │   │   └── content_loader.dart
│   │   ├── services/
│   │   │   ├── progress_service.dart       (shared_preferences)
│   │   │   └── audio_service.dart          (just_audio)
│   │   └── screens/
│   │       ├── home_screen.dart            (3 메뉴: 회화·플래시카드·즐겨찾기)
│   │       ├── conversation_screen.dart    (PageView 200 turn + 자동재생)
│   │       └── flashcard_screen.dart       (탭 flip + 다시/알아, 문장/부사 토글)
│   ├── assets/
│   │   ├── data/
│   │   │   ├── dialogues/L1.json           ← SOT (200 turn)
│   │   │   ├── dialogues/_meta.json
│   │   │   └── wordsets/adverb_hooks.json  (89 핵심 부사)
│   │   └── audio/
│   │       ├── female/turn_001..200.mp3    (Azure YesuiNeural)
│   │       └── male/turn_001..200.mp3      (Azure BataaNeural)
│   ├── android/   (flutter create 생성)
│   ├── web/
│   ├── test/
│   └── pubspec.yaml
│
├── db/                              ← 분석 자료 / 옛 데이터 (앱이 안 씀)
│   ├── corpus/                        단국대 A1/A2/B1 textbook + 더바른 OCR + Leipzig
│   ├── notes/                         몽골어 200.md + 옛 Discover 룸 README/NOTES
│   └── legacy/                        옛 5-episode dialogue split + wordset v1
│
├── scripts/
│   └── tts_azure.py                   Azure Speech REST (--resume 지원)
│
├── README.md
└── .gitignore
```

**참고**: 처음엔 `content/` 를 SOT 로 두고 `app/assets/` 로 복사했으나, mn 은 단일 앱이라 중복이 무의미해서 **`app/assets/data/`** 와 **`app/assets/audio/`** 가 SOT 가 됨. 직접 편집 → `flutter run` 만 하면 반영.

---

## 빌드 & 실행

```powershell
cd D:/OneDrive/talkverse/mn/app
flutter pub get
flutter run                 # 디바이스 / 에뮬레이터
flutter build apk --release # Android APK
flutter build web --release # 웹
flutter test                # 위젯 테스트
```

검증 결과 (2026-05-17):
- `flutter analyze` → No issues found
- `flutter test` → All tests passed
- `flutter build web --release` → 성공
- `flutter build apk --release` → 52.7MB APK
- SM-S936N (Galaxy S24 Ultra) 설치·실행 확인

---

## MVP 화면

| 화면 | 기능 |
|---|---|
| **Home** | hero (진도/즐겨찾기) + 3 메뉴 |
| **Conversation** | 200 turn PageView · 자동재생 · voice toggle (♀ Yesui / ♂ Bataa) · 한국어 탭 보기 · hint · 즐겨찾기 · 진도 자동 저장 |
| **Flashcard** | 탭 flip (앞: mn, 뒤: ko + pron + hint) · 다시/알아 버튼 deck 순회 · 문장 200 ↔ 부사 89 토글 · 자동재생 (문장만) |
| **Favorites** | 저장한 문장 리스트 |

---

## Stack

| | |
|---|---|
| Framework | Flutter 3.41+ |
| Language | Dart 3.11+ |
| State | setState |
| Storage | shared_preferences |
| Audio | just_audio (asset mp3) |
| Targets | Android · Web |

---

## TTS 합성 (Azure)

```powershell
cd D:/OneDrive/talkverse/mn/scripts
python tts_azure.py --voice female --resume
python tts_azure.py --voice male --resume
```

- 키: `C:/Users/Administrator/Downloads/talkverse-learning/talkverse-learning/.env` (`AZURE_SPEECH_KEY`, `AZURE_SPEECH_REGION=koreacentral`)
- Voice: `mn-MN-YesuiNeural` (여), `mn-MN-BataaNeural` (남)
- 출력: `app/assets/audio/{female,male}/turn_001..200.mp3` (≈ 5.8MB)
- L1.json 갱신 → `--resume` 재실행하면 변경된 turn 만 새로 합성 (size 기준)

---

## 데이터 출처

- **단국대 표준 몽골어 교재** (A1 / A2 / B1) — `db/corpus/mn_A?_textbook.md`
- **더바른 몽골어** — `db/corpus/mn_더바른_textbook.md` (OCR)
- **BOOKS/몽골어 200.md** — 200 문장 + 부사 hook 원본 메모 (`db/notes/`)
- **Leipzig MN OpenSubtitles top2500** — `db/corpus/lang_mn_*.csv`
- **Azure Speech mn-MN Neural voices** — 음성 합성

---

## 차별점

- **한 앱 = 한 언어** (talkverse "한 언어 한 앱" 룰)
- **표준어 (Khalkh) 1개**
- **부사 hook 200 문장** — 30 핵심 부사가 5-10회 반복 노출
- **한국 화자 한정** — 번역·발음 모두 한국어 기반 (`pron` 필드)

---

## 다음 단계 (M2~)

- [ ] SRS 복습 알고리즘 (Anki-style spaced repetition)
- [ ] 부사 hook → L1 turn 매핑 (탭 시 부사 포함 문장 모두 보기)
- [ ] L2 / L3 dialogue 작성 (단국대 교재 기반)
- [ ] launcher icon (🇲🇳 / 🐎 모티프)
- [ ] iOS 빌드 (필요 시)

---

_갱신: 2026-05-17_
