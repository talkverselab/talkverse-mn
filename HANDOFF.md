# HANDOFF — talkverse-mn (몽골어) — 2026-11-03

> **⛔ 콘텐츠 생성 금지(사용자 지시 2026-11-02)** — 회화·단어·예문·문법 설명·음성 등 새 학습 콘텐츠를 만들거나 다시 쓰지 말 것(사용자 지시가 있을 때만). 공통 지침 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md`.

## 진행 단계 (일본어앱 구조 복제)

| 단계 | 상태 |
|---|---|
| ① 캐릭터 시안 | **통과 2026-11-03** — `data/review/art/chars_mn_v1.jpg`, `CHARACTERS.md` |
| ② UX/UI 시안 | **통과 2026-11-03** — `data/review/uxui/sian_mn_01.jpg`(시안 02 + 「어순 맞대기」), 답 글 `sian_mn_01_img.md` |
| ③ 아이패드 빌드 | Android 끝 — 커밋 `03544cc`, CI 빌드 12, Zealot https://apps.talkverse.uk/xBHY8/201, PC 백업. 아이패드 스크린샷 9장 넘침 0·테스트 통과(`app/integration_test/dialogue_pane_test.dart`, `app/tools/pane_shots.py`, 시뮬레이터 `mn-shots-ipad` C2345B5E…). **TestFlight 업로드 성공 — 빌드 2611030055**(2026-11-03 00:58, PC 백업 `D:\OneDrive\app project\mn_app\ios\`). 단 IPA 에 Sign in with Apple 권한이 빠짐(포털 capability 꺼짐) → Apple 로그인만 안 됨 |
| ④ 회화 | 보류(사용자 지시 뒤). 그때 Grok 재작성 뒤 **Gemini 검수도**(몇 편 해 보고 별로면 중단 보고) — `CHARACTERS.md` 끝 메모 |

## 이번에 한 것 (2026-11-02~03)
- Supabase 제거·저작권 정리·이력 정리(filter-repo, 강제 push) — `docs/CLOUDFLARE_MIGRATION.md`.
- Talkverse ID 로그인(선택)·평생 이용권 결제 연동 `f8f04d5` — 잠금 없음(사용자 결정), client_id `mn`, 딥링크 `talkverse.mn://auth`.
- iOS: 아이콘 1024 + 다크·틴티드, `app/tools/ios_release.sh`. 2026-11-03 TestFlight 업로드 성공(빌드 2611030055).
- 단어 그림: `talkversehanja` `talkverse_art/words/mn.csv`(250)·`mn_food.csv`(50) 푸시(fa49e98) → `/art/mn/manifest` 124장 적재(앱이 자동으로 씀).
- 아이콘은 talkverse.uk 세션 담당(직접 고치지 말 것).
- 회화 원칙 링크·몽골어 특이점 `docs/DIALOGUE.md`.
- **접사(2026-11-03 사용자 지시)** `5a1adff`: 접사표 19개 + 자동 분석(`app/lib/data/mn_affixes.dart`), 어순 맞대기의 접사 블록·조사 테두리, 모음조화 연출 시트, 접사 카드, 홈 「접사 사전」. CI 빌드 13 · Zealot https://apps.talkverse.uk/xBHY8/217. iOS 는 아직 2611030055(접사 전) — M6 부하로 재업로드 보류. 터키어앱 세션에 구조 전달함.
- **동사 형태 맵(2026-11-03, Grok 글 시안 `data/review/uxui/sian_mn_grok_01.md` ③ 사용자 선택)**: 홈 「동사」, 앱에 나온 형태 + 규칙형(흐리게). CI 빌드 14 · Zealot https://apps.talkverse.uk/xBHY8/220. 시안의 나머지(존대·반말 카드, 장모음·Ө·Ү 듣기, х·ц·л 자음)는 새 문장·음성이 필요해 보류 — 시안 속 몽골어 예시는 틀린 것이 많음(쓰지 말 것).

## 알아 둘 것
- 홈 화면에 스페인어 템플릿 잔재(「¡Hola!」·「PRINCIPIANTE 1」·「Minjun & Lucía」·진행 탭 「Poco a poco…」)가 남아 있음 — 문구 수정은 콘텐츠 금지가 풀리거나 사용자 지시가 있을 때.
- 「어순 맞대기」의 한국어 낱말 대응은 턴 `align` 데이터가 있어야 나옴(회화 작업 때 채움). 지금은 몽골어 낱말 칩 + 모음조화 점만.

## 다음 할 일(세션)
- 사용자가 회화 작업을 풀면 ④(`LANG_APP_REPLICATE_PROMPT.md` §12): R 구조 편 파일 → Grok 재작성 → Gemini 검수 → 장면 컷 4장/편(한자 세션 경유) → 턴 `art`·`align` 채우기.
- 홈 템플릿 문구 정리(사용자 지시 시).
- Apple capability 켜지면 iOS 재업로드.

## 사용자가 할 일
- TestFlight 내부 테스트 그룹에 빌드 2611030055 추가·설치 확인.
- 개발자 포털 App ID `com.talkverse.mongolianUniverse` 에 **Sign in with Apple** 켜기 → 그 뒤 `bash app/tools/ios_release.sh` 로 다시 올림(지금 빌드는 Apple 로그인 권한 없음). 스토어 인앱 상품(iOS `com.talkverse.mongolianUniverse.lifetime` / Android `lang_mn`).
- Supabase `tts` 버킷의 몽골어 음성(맨 위 578 + `mn/` 1,546) 삭제.

## 주의
- 새 키스토어 금지, `applicationId kr.mlab.mn` 유지. 로컬 빌드 번호는 CI 실행 번호보다 크게.
- M6 자원: 시뮬레이터는 자기가 켠 1대만, 과부하 공지면 바로 멈춤. 코드 push 는 폰 업데이트 알림이 가니 묶어서.
- Zealot 앱이름 「몽골어유니버스」(`app/CLAUDE.md` §8, 올리기 `app/tools/zealot_push.sh`).
