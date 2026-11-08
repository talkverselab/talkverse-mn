# HANDOFF — talkverse-mn (몽골어) — 2026-11-08

> **⛔ 콘텐츠 생성 금지(사용자 지시 2026-11-02)** — 회화·단어·예문·문법 설명·음성 등 새 학습 콘텐츠를 만들거나 다시 쓰지 말 것(사용자 지시가 있을 때만). 공통 지침 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md`.

## 진행 단계 (일본어앱 구조 복제)

| 단계 | 상태 |
|---|---|
| ① 캐릭터 시안 | **통과 2026-11-03** — `data/review/art/chars_mn_v1.jpg`, `CHARACTERS.md` |
| ② UX/UI 시안 | **통과 2026-11-03** — `data/review/uxui/sian_mn_01.jpg`(시안 02 + 「어순 맞대기」), 답 글 `sian_mn_01_img.md` |
| ③ 아이패드 빌드 | Android 끝 — 커밋 `03544cc`, CI 빌드 12, Zealot https://apps.talkverse.uk/xBHY8/201, PC 백업. 아이패드 스크린샷 9장 넘침 0·테스트 통과(`app/integration_test/dialogue_pane_test.dart`, `app/tools/pane_shots.py`, 시뮬레이터 `mn-shots-ipad` C2345B5E…). **TestFlight 업로드 성공 — 빌드 2611030055**(2026-11-03 00:58, PC 백업 `D:\OneDrive\app project\mn_app\ios\`). 단 IPA 에 Sign in with Apple 권한이 빠짐(포털 capability 꺼짐) → Apple 로그인만 안 됨 |
| ④ 회화 | 보류(사용자 지시 뒤). **범위 150편·R3 까지(185위)·카오스 45편+**(`docs/DIALOGUE.md`). 절벽 단어 1,500 = talkversehanja words/mn.csv b53def1. 그때 Grok 재작성 뒤 **Gemini 검수도**(몇 편 해 보고 별로면 중단 보고) — `CHARACTERS.md` 끝 메모 |

## 이번에 한 것 (2026-11-02~03)
- Supabase 제거·저작권 정리·이력 정리(filter-repo, 강제 push) — `docs/CLOUDFLARE_MIGRATION.md`.
- Talkverse ID 로그인(선택)·평생 이용권 결제 연동 `f8f04d5` — 잠금 없음(사용자 결정), client_id `mn`, 딥링크 `talkverse.mn://auth`.
- iOS: 아이콘 1024 + 다크·틴티드, `app/tools/ios_release.sh`. 2026-11-03 TestFlight 업로드 성공(빌드 2611030055).
- 단어 그림: `talkversehanja` `talkverse_art/words/mn.csv`(250)·`mn_food.csv`(50) 푸시(fa49e98) → `/art/mn/manifest` 124장 적재(앱이 자동으로 씀).
- 아이콘은 talkverse.uk 세션 담당(직접 고치지 말 것).
- 회화 원칙 링크·몽골어 특이점 `docs/DIALOGUE.md`.
- **접사(2026-11-03 사용자 지시)** `5a1adff`: 접사표 19개 + 자동 분석(`app/lib/data/mn_affixes.dart`), 어순 맞대기의 접사 블록·조사 테두리, 모음조화 연출 시트, 접사 카드, 홈 「접사 사전」. CI 빌드 13 · Zealot https://apps.talkverse.uk/xBHY8/217. iOS 는 2611030755(접사·동사 맵 포함, 2026-11-03 07:56) TestFlight 업로드. 터키어앱 세션에 구조 전달함.
- **동사 형태 맵(2026-11-03, Grok 글 시안 `data/review/uxui/sian_mn_grok_01.md` ③ 사용자 선택)**: 홈 「동사」, 앱에 나온 형태 + 규칙형(흐리게). CI 빌드 14 · Zealot https://apps.talkverse.uk/xBHY8/220. 시안의 나머지(존대·반말 카드, 장모음·Ө·Ү 듣기, х·ц·л 자음)는 새 문장·음성이 필요해 보류 — 시안 속 몽골어 예시는 틀린 것이 많음(쓰지 말 것).

- **일본어앱 11-04 변경 이식(2026-11-04, 공통 프롬프터 §5-1)** `0a5d5bd`: ① 「오늘의 컷」 대사는 그림 아래 띠, 재생 화면 컷엔 말풍선 없음 ② 그림 카드 앞면에 한국어 뜻 + 「이 말을 몽골어로 해 보세요」 ③ 문장 레마 칩 ↔ 단어장 — 단어장 = 그림 목록과 같은 1,500(`app/assets/data/freq/mn_words.csv`, 빈도 단어 화면도 이것), 레마는 턴 `lemmas` 가 있으면 그것, 없으면 접사 떼기로 앱이 찾음(`lib/services/word_lookup.dart`), 칩 누르면 단어 시트 ④ 시작 때 그림 기기 내려받기(`content_sync.dart`·`sync_screen.dart`, 모든 그림 `artProvider`) ⑤ `assets/data/version.json` db=3(데이터 바꾸면 이 번호만 올림) ⑥ `{name}` 회화를 열 때 이름 비면 이름·성별 창 ⑦ 여자 학습자면 `<편id>_f` 컷 먼저. CI 빌드 15 · Zealot https://apps.talkverse.uk/xBHY8/261 · TestFlight 2611040328. 아이패드 스크린샷 14장 넘침 0. ⑧ 조연 캐릭터 시트는 Grok 그림이 필요하고 조연이 나오는 편이 아직 없어 회화 작업 때.

- **단어·메뉴 개편(2026-11-07, `~/talkverse/ja/docs/MENU_WORDS_2026-11-07.md` §1·§3~§6)**: 절벽 단어 = 20어 단원·네모 타일·「회화 단어 포함」(탭 = 발음, 길게 = 단어 시트, 검색 유지). **R5 는 1,500위에서 끊음**(목록이 1,500개, 누적 89.2% — 일본어 2,000 대신). 경계는 코드 한 곳 `lib/core/cliff.dart`(49·71·185·522). `mn_words.csv` 의 level 칸이 옛 값(129·187·390·823)이라 공식 값으로 고침 — **db 번호는 안 올림**(올리면 재시딩이 회화 진행 기록을 지운다), 화면은 `regionOf(rank)` 를 씀. 회화 단어 = 회화 낱말 중 목록 밖이면서 `travel_words.json` 에 뜻이 있는 것(`convExtraWords`, 편이 적어 지금은 거의 없음). 「앱 소개」(`about_screen.dart`, 레일 맨 아래·프로필 → 정보). 홈 메뉴 = 문법 → 회화 → 단어 → 참고, 「빈도 단어」→「절벽 단어」, 「말하기」→「문장 말하기」, 준비 중이던 「발음」 칸 삭제. 프로필 = 계정·기록·학습자 프로필·설정·정보(앱 업데이트·TTS·테마·변종·Stack 삭제). 성과는 「진행」 탭에 그대로. 회화 문장 = 낱말 탭 → 단어창, 길게 → 접사 시트(`selectable_mn_text.dart`). 읽기 보조 = 한글 독음 전역 토글 기본 미표시(`KoReadingPrefs`, 켤 때 안내). §2(문자 기준 절벽)는 몽골어 해당 없음. 커밋 `29e5769`, CI 빌드 16 · Zealot https://apps.talkverse.uk/xBHY8/305 · TestFlight 2611071743. 넘침 확인은 `test/screens_fit_test.dart`(시뮬레이터 없이 300~1024 폭)로만 함 — 그날 공용 시뮬레이터 서비스가 멈춰 **아이패드 스크린샷 미확인**(`integration_test` 에 15~17번 샷을 추가해 둠, 풀리면 `tools/pane_shots.py` 로 볼 것).

- **2026-11-08**: 시뮬레이터 복구 뒤 아이패드 스크린샷 확인 — 「앱 소개」가 레일을 가리던 것(레일은 칸 바깥 → 칸 Navigator 에 직접 push)·메뉴 칸 이름 두 줄·R3 칩 색 고침 `be091d4`(CI 17 · Zealot 352 · TestFlight 2611081635). **키릴 문자와 발음**(공통 프롬프터 §5-3) `42683ed`: 홈 「기초」 첫 칸, 35자 격자 + 묶음 칩(모음조화 남성·여성·중성, 이+모음, 자음, 외래어 글자, 부호) + 로마자 토글, 글자 탭 = 1초 뒤 글자 소리(번들 음성 35자 모두 있음)·IPA·소리 나는 곳·조음/모음 위치 그림(임시 — 출처 표기 안 함, 출시 전 Grok 그림으로 교체)·한국어 비교·예시 단어(그 글자가 들고 번들 음성이 있는 것만). 데이터 `lib/data/mn_letters.dart` — 설명은 Claude 작성이라 원어민 확인 필요. CI 18 · Zealot https://apps.talkverse.uk/xBHY8/367 · TestFlight 2611081658. 스크린샷 19장 넘침 0.
- **회화(2026-11-07 제한 해제)**: Claude 초안 샘플 6편(R1) `app/assets/data/dialogues/R1/` — 사용자 톤 확인 대기, 확인되면 나머지 144편. 감정 열(emotion·segs)·검사기 `tools/check_dialogues.py`·리뷰 페이지 `tools/review_html.py` → `data/review/REVIEW_mn.html`(음성 칸 없음)·음성 감정 계획 `tools/tts/build_plan.py`. Grok 은 11/9 13:30 재개.

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
- **2026-11-03 Grok 새 계정**(M4 ~/chrome-grok, 포트 9222; 옛 계정 주간 한도 11/9 초기화) — 옛 프로젝트·챗 링크는 안 열림, 새로 만들기. 자기 프로필 `~/chrome-grok-mn`(포트 9235)은 Chrome 끄고 M4 안에서 쿠키 다시 복사 후 재시작. 절차: 샘플 1~2개 먼저 → PushNotification 으로 사용자 통과 요청 → 통과 뒤 본작업. 한도는 모든 세션 공유.
- Grok·Gemini 를 직접 쓸 때(지금은 한자 세션 경유): 로그인 원본은 M4 `~/chrome-grok`, 쿠키 복사는 M4 안에서만, 자기 포트로 띄우고 M6 에서 ssh 터널 — `~/talkverse/GROK_M4_LOGIN.md`. 사용자 지시가 있을 때만 켜고, 한 번에 한 작업, 탭·Chrome 은 끝나면 닫기.
- 새 키스토어 금지, `applicationId kr.mlab.mn` 유지. 로컬 빌드 번호는 CI 실행 번호보다 크게.
- M6 자원: 시뮬레이터는 자기가 켠 1대만, 과부하 공지면 바로 멈춤. 코드 push 는 폰 업데이트 알림이 가니 묶어서.
- Zealot 앱이름 「몽골어유니버스」(`app/CLAUDE.md` §8, 올리기 `app/tools/zealot_push.sh`).
