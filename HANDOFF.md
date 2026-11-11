# HANDOFF — talkverse-mn (몽골어유니버스) — 2026-11-10 세션 종료(M6 디스크 정리)

> 공통 지침 `~/talkverse/LANG_APP_REPLICATE_PROMPT.md`. 회화 밖 콘텐츠(단어·문법 설명 등) 새로 쓰기는 사용자 지시가 있을 때만. 회화는 2026-11-07 해제.



## 2026-11-11 19:30 — 몽골어 검수·음성 끝
- **Gemini 반영 150/150**(`73181e0`, 남은 23편은 3편 묶음 답 — 나눔 23 빠짐 0). 검사 「150편 · 오류 0」.
- 비어 있던 어휘 note 145줄 채움(`73bc71b`, 형식 「단어 = 뜻」).
- Azure 음성 150편 다시 만들어 올림(m/f, `data/tts/audio_mn.json`), 리뷰 페이지 음성 켜고 게시(`2a26c9e`, uk Version 1b911761…). `app/assets/audio/manifest.json` 도 갱신됐지만 원래 dirty 파일이라 커밋 안 함.
- **3편 묶음 루프** `tools/gemini_loop3.sh` 는 이제 **미얀마어 150편(50묶음)** 진행 중 — 답 `~/talkverse/my/data/review/dialogues/<편>_gemini.md`, 로그 `data/review/gemini/log.txt`. 재부팅되면 M6 터널(`ssh -fN -L 9235:127.0.0.1:9235 macmini4`) 열고 루프 다시 켤 것. 미얀마어 반영은 따로(my 저장소).
- 남은 것: 미얀마어 검수 끝나면 반영, Grok 18편 11/16 뒤 새 방에서, 다 끝나면 9235 탭·터널 닫기.

## 2026-11-11 02:30 — Grok 한도·Gemini 다음 언어
- 사용자 지시 「그록한도까지 사용 그래도 제미나이는 계속 진행 몽골어 다음 소수언어도 제미나이작업은 계속」.
- Grok: PC 9253 은 로그아웃돼 있었고 uk 9231 도 꺼져 있어 M4 9226(~/chrome-grok)에서 쿠키 동기화 → 전문가 확인 → 남은 18편(`data/review/grok/todo.txt`) 시작했으나 첫 편에서 **LIMIT**(주간 한도, 11/16 초기화). 옛 방 b7a785a6 은 이 로그인에선 입력창 없음 → 다음엔 새 방(GROK_CHAT 비움). 재작성한 편에 이미 `_gemini.md` 가 있으면 지우고 다시 검수.
- Gemini: 몽골어 루프 진행 중(90/150 반영 78). `tools/gemini_next.sh` 가 몽골어 「끝」 뒤 **미얀마어 150편**을 같은 크롬 9235(4 Argon)로 이어 검수(답 `~/talkverse/my/data/review/dialogues/<편>_gemini.md`, 로그 `my/data/review/gemini_log.txt`; Grok 안 된 R3 14편은 맨 뒤). 반영은 세션이 따로.

## 지금 상태

| 항목 | 상태 |
|---|---|
| 최신 빌드 | 커밋 `dfc3f59` · Android CI 21 · Zealot https://apps.talkverse.uk/xBHY8/408 · TestFlight 2611091136 · PC 백업 `D:\OneDrive\app project\mn_app\` |
| ① 캐릭터 | 통과 2026-11-03 — `CHARACTERS.md`, `data/review/art/chars_mn_v1.jpg` |
| ② UX/UI | 통과 2026-11-03 — `data/review/uxui/sian_mn_01.jpg` |
| ③ 아이패드 빌드 | 끝. 스크린샷 `app/integration_test/dialogue_pane_test.dart` + `app/tools/pane_shots.py <UDID> <폴더>`(시뮬레이터 `mn-shots-ipad` C2345B5E-F6D2-441C-B796-2216C7C880D4), 22장 넘침 0 |
| ④ 회화 | **Claude 초안 150편 끝(검수 전)** — R1 90 · R2 36 · R3 24, 카오스 51(34%), 모든 턴 감정 열. 앱에는 아직 안 실림(로더는 `L1.json` 2편만) |
| 출시 | **안 함** — 지금은 한자앱만 심사, 언어앱은 완성된 것부터 하나씩 |
| 통합 앱 | 연결 준비 끝, uk 가 통합 앱 빌드 2에 넣음(https://apps.talkverse.uk/IfB4M/411) |

## 앱에 있는 것(2026-11-02~09)
- 일본어앱 구조: 두 화면(레일·왼쪽 칸·오른쪽 칸), 회화 리더(장면 컷 + 대사 띠), 그림 카드, 오늘의 컷, 성과(진행 탭), 학습자 이름·성별, 그림 기기 내려받기(`ContentSync`).
- 홈 「기초」: **키릴 문자와 발음**(35자·모음조화 칩·로마자 토글·발음 시트, 데이터 `lib/data/mn_letters.dart`), **키보드 연습**(옛 아랍어앱 것을 왼쪽→오른쪽으로, 시스템 몽골어 입력기). 「문법」: 접사 사전(19개, `lib/data/mn_affixes.dart`)·동사 형태 맵·문법 레슨. 「회화」·「단어」(절벽 단어 20어 단원·타일, 주제 단어, 표현, 단어 카드)·「참고」(청크 검색).
- 회화 문장 낱말 탭 → 단어창, 길게 → 접사 시트(`widgets/selectable_mn_text.dart`). 한글 독음 전역 토글 기본 미표시(`KoReadingPrefs`).
- 절벽 경계는 코드 한 곳 `lib/core/cliff.dart`(49·71·185·522, R5 는 1,500위까지 누적 89.2%). 「앱 소개」(레일 맨 아래·프로필 → 정보).
- 결제: `~/talkverse/PRICING.md` 상품 6개(`lib/data/purchase.dart` `kMnPlans`), 결제 시트 규정 표기·복원·약관/방침 링크. **잠그는 기능은 없음**(사용자 결정 2026-11-02).
- 통합 앱 연결: `lib/embed.dart`(embedInit·embedApp·appDb), `lib/core/embed_env.dart`(assetPath·dataDir), `lib/core/prefs.dart`. **새 코드에서 설정은 `Prefs.getInstance()`, 에셋은 `assetPath()`** — 안 그러면 통합 앱에서 깨진다.

## 회화 작업(다음 할 일)
- 초안: `app/assets/data/dialogues/R<레벨>/<주제>/<편id>.json`, 규칙 `tools/prompts/dialogue_mn.md`, 검사 `python3 tools/check_dialogues.py --fix-rd --report`(150편 오류 0), 리뷰 페이지 `python3 tools/review_html.py` → `data/review/REVIEW_mn.html`(uk 에 「REVIEW_mn 갱신」), 음성 감정 계획 `python3 tools/tts/build_plan.py` → `data/tts/plan/`.
- 다음 순서(`~/talkverse/GEMINI_REVIEW_GUIDE.md`): **Grok 재작성(11/9 13:30 재개)** → 최소 수정 → **Gemini 3.1 Pro 검수**(한 번에 한 건·60초 간격, BLOCKED 면 멈추고 사용자에게) → 사용자 리뷰 통과 → 로더를 R 구조로 옮기고 빌드 → 장면 컷 요청.
- **Grok 은 PC 에서(사용자 지시 2026-11-09 「소수언어들에게 pc에서 그록 켜서 집필 그림 작업 하라고 해」)**: PC(`ssh Administrator@100.127.143.37`)에서 크롬을 `--remote-debugging-port=9253 --remote-debugging-address=127.0.0.1 --user-data-dir=D:\chrome-grok-mn https://grok.com` 으로 띄우고(SSH 에서 직접 띄우면 세션과 함께 죽으니 작업 스케줄러 `Grok-Chrome-mn-9253` 으로 — 헝가리어앱 `Grok-Chrome-hu-9247` 과 같은 방식. **예약 작업 `Grok-Chrome-mn-9253`(사용자 john, 트리거 없음·수동 실행) 2026-11-09 사용자 「진행」으로 만듦 — 켜기: PC 에서 `Start-ScheduledTask -TaskName Grok-Chrome-mn-9253`**. 쿠키 동기화 직후 화면이 하얗게 비면 탭 새로고침 뒤 grok_mode), M4 에서 `ssh -fN -L 9253:127.0.0.1:9253 pc` 터널 → M4 에서 `/usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 9253`(값은 출력·파일에 안 남음). 포트 **9253**(9245 는 미얀마어앱이 사용 중이라 옮김)는 `~/talkverse-uk/docs/GROK_CHROME_PORTS.md` 에 등록함. **켠 뒤 모델이 「전문가」인지 먼저 확인**(사용자 지시 2026-11-09): M4 에서 `/usr/bin/python3 ~/talkverse-uk/tools/grok_mode.py 9253`(보기만은 `--check`), 또는 화면의 입력창 옆 모델 단추 → 전문가. 계정 주간 한도를 모든 세션이 같이 쓰니 회차는 작게.
- **Grok 프롬프트 최소화(사용자 지시 2026-11-09, uk 전달)**: 규칙은 문서 하나에 한 번만 쓰고, 방 첫 메시지에서 「앞으로 파일 이름 한 줄만 보낸다」고 약속한 뒤 편마다 한 줄만 보낸다(긴 프롬프트를 매번 붙이지 않는다 — 토큰). 그림이 처음과 달라지면 최초 통과 그림을 기준으로(이미 만든 것은 그대로).
- **진행(2026-11-10 00:30 사용자 지시로 대기)**: 동떨어진 30편 중 13편 반영(`7fde345`). 남은 17편 = r1_life_c3(답 잘림)·r2_friends_b1·r2_life_b5·r2_love_b2·r2_love_b5(3분 초과로 중지) + 아직 안 보낸 r2_love_c3·r2_travel_b1·r2_travel_b2·r2_work_b1·r2_work_b6·r3_friends_b2·r3_life_b3·r3_life_b4·r3_travel_b1·r3_work_b1·r1_life_a3·r1_life_b3·r2_work_b4. 3분 안에 거의 안 끝나니(편당 7~8분) 다시 할 때 한 번에 보내는 양·대기 방식을 사용자와 정할 것. Grok 방 https://grok.com/c/b7a785a6-aca6-4490-9012-543828ebaa3e
- **Grok 답은 3분까지만(사용자 지시 2026-11-10)**: `grok_text.py` 기본 `--wait 180`, 넘으면 생성 중지(중지 단추, 없으면 Escape)·저장 안 함(종료 코드 4) → 로그 「시간초과」 편만 나중에 다시.
- 감정 열(emotion·segs)은 150편 초안에 이미 있음 — 재작성 뒤에도 줄마다 유지·갱신.
- **일상 속 반전(사용자 지시 2026-11-09, 정정)**: 반전·러브·플러팅은 비율 그대로 다 넣되 실제 일상 장면·표현 흐름 속에서, 비현실적 설정만 금지(규칙 `tools/prompts/dialogue_mn.md` 맨 앞). 150편 점검 결과 **동떨어진 30편 목록 = `docs/DIALOGUE.md` 끝** — 아직 안 고침, Grok 재작성 때 이 30편부터 반전은 살리고 설정만 현실적으로 고친다.
- Grok 때 정리할 것(`docs/DIALOGUE.md`): 겹치는 농담(단톡방 하트 2·「네」만 하다 커짐 3·세배 줄 2·비슷한 단어 말실수 5), 반전이 앞쪽(3~4턴)인 6편. 작성 묶음들이 표시한 「원어민 확인 필요」 표현은 Gemini 검수 프롬프트에 함께.
- 음성: MOSS·VoxCPM2 가 몽골어 미지원 — 모델은 사용자 결정 뒤(uk 가 알림). 지금 앱 음성은 번들 mp3 578줄 + 글자 35자.

## 2026-11-10 오후 — 집필 마무리 = Gemini 검수(사용자 지시 「그림빼고 제미나이검수로 해서 집필은 완료해」)
- **남은 Grok 재작성 17편은 하지 않는다** — Gemini 검수로 집필 완료. 그림은 나중.
- Gemini: M4 크롬 9235(`~/chrome-grok-mn`, M6 터널 `ssh -fN -L 9235:127.0.0.1:9235 macmini4`), 모델 4 Argon. `tools/gemini_loop.sh` 가 끝까지 돈다(한도 걸리면 20분마다 재시도, BLOCKED 면 멈춤). 로그 `data/review/gemini/log.txt`, 답 `data/review/dialogues/<편>_gemini.md`. 한도는 약 17~30편마다 걸리고 5시간쯤 뒤 초기화.
- 반영: `tools/apply_fix.py <fix.json>`(바뀐 턴 rd 재생성 + 검사), 편 JSON `review` 에 한 줄. 실제 오류만, 반전·농담·표현 풀은 유지. 51/150 반영(커밋 `462265d`).
- **음성은 검수 다 끝난 뒤(사용자 지시 「음성은 제미나이 검수 끝나고 하자」)**: `doppler run -p keys -c prd -- python3 tools/tts/azure_pack.py all --upload` (Azure mn-MN Yesui·Bataa, R2 audio/mn + D1 audio_lines). 옛 대본 음성 134편이 올라가 있음 → 전부 다시. 그 뒤 `python3 tools/review_html.py`(NOAUDIO 없이) → M4 talkverse-uk 로 게시.
- 리뷰 페이지 https://talkverse.uk/talkverse/review/mn/ — 한 편씩, 채팅 배치. 게시는 M4 `~/talkverse-uk` 에 scp + commit + `npx wrangler deploy`(M4 GitHub 로그인 풀려 push 실패 중 — uk 세션 몫). 페이지에 업체 이름(Azure 등) 넣으면 출처 검사에 걸림.

## 2026-11-10 종료 시점
- 회화 Grok 재작성 13/30 반영(`7fde345`), 남은 17편은 위 「진행」 줄. Grok 주간 한도 11/16 초기화 — 그 전엔 쓰지 말 것.
- **DB 올리기(사용자 지시 11/10 「모든 자산 db 에」) 못 함**: 대상은 D1 `talkverse-db` `audio_lines`(lang·episode·turn·voice·key NOT NULL…, 다른 언어는 `~/talkverse/<lang>/tools/tts/pack.py` 로 R2 `talkverse-art` audio/<lang>/<편>/<턴>_<m|f>.mp4 + 행). mn 은 0행 — 150편 회화 음성이 아직 없어(MOSS·VoxCPM 몽골어 미지원) 행을 못 만든다. 번들 mp3 578개(`app/assets/audio`, 옛 L1 구조)는 편·턴 형식이 아님 → 올릴지·어떻게 매핑할지 확인 필요. 장면 컷 0장.
- 정리: `.dart_tool`·`android/.gradle`·`ios/Pods`·`.symlinks`·`__pycache__` 삭제(약 114MB). 다음 빌드 전 `flutter pub get`·`pod install`. 지울 후보(안 지움): `scripts/_corpus_*.{tsv,txt}`(2.2MB, 재생성 방법 불확실), `db/gemini_check/`.
- PC 크롬 9253 은 창만(빈 탭) 남김, 터널 모두 닫음. 예약 작업 `Grok-Chrome-mn-9253` 은 트리거 없이 남아 있음.

## 출시 전 걸림돌(지침 2.1·4.3)
- 회화 2편뿐 → 150편 검수 뒤 로더 이전.
- 홈 스페인어 템플릿 잔재(「¡Hola!」·「PRINCIPIANTE 1」·「Minjun & Lucía」)·진행 탭 「Poco a poco…」·학습 탭 회화 목록의 「준비 중」 레벨.
- 키릴 문자 발음 설명·회화 원어민 확인. 조음 그림은 임시(출처 표기 안 함, 출시 전 Grok 그림으로 교체).
- 스토어 설명 `app/docs/store/listing.md`·심사 메모 `app/docs/store/review_notes.md` 의 회화 편 수·음성 줄 수 채우기. 스크린샷 첫 두 장 = 키릴 문자표·접사 사전.
- Apple 로그인 권한(포털 capability).

## 공통 절차
- 앱을 고치면 **Android(Zealot)와 iOS(TestFlight)를 함께**: 커밋·push → CI(`release.yml`, 빌드 번호 = 실행 번호; HEAD 가 `[skip ci]` 면 `gh workflow run release.yml --ref master`) → **CI 가 성공하고 `latest.json` sha 가 그 커밋일 때만** `gh release download latest -R talkverselab/talkverse-mn -p app-latest.apk -p latest.json` → apksigner SHA-1 `9cc4bc93…` 확인 → `~/bin/zealot-upload app-latest.apk "몽골어유니버스" -c "…"` → `scp` PC 백업. iOS 는 `bash app/tools/ios_release.sh`(백그라운드, 끝나면 ios xcconfig·pbxproj·xcscheme·xcworkspace 잡음 `git checkout`). CI 가 Gradle 504 로 실패하면 몇 분 뒤 `gh run rerun`.
- 스크린샷 넘침 0 · `flutter analyze` · `flutter test`(26개) 확인 뒤 배포.
- M6: 시뮬레이터는 자기 것 1대만, **디스크가 빠듯함(2026-11-09 99%)** — 스크린샷·APK 는 스크래치에서 바로 지우고, 빌드 뒤 필요하면 `flutter clean`.
- Grok·Gemini 는 사용자 지시가 있을 때만, 탭·Chrome 은 끝나면 닫기. **2026-11-09 허브 공지(`~/logs/rc/RELAY_grok_20261109.md`)**: Grok 은 옛 계정으로 다시 로그인됨(M4 uk 크롬 9231 — uk 방은 건드리지 말 것). 한자 세션은 이제 다른 세션 요청을 대행하지 않음 → 자기 크롬(M4 프로필 `~/chrome-grok-mn`, 포트 9235)을 켜고 M4 에서 `/usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 9235`(`ssh macmini4` 경유)로 쿠키 동기화 뒤 직접. 도구는 M6 `~/Hanja/tools/grok_req.py`·`grok_cdp.py` 를 저장소로 복사. 새 키스토어 금지, 시크릿 값은 어디에도 적지 않음(Doppler).

## 사용자가 할 일
- 개발자 포털 App ID `com.talkverse.mongolianUniverse` 에 Sign in with Apple 켜기.
- 스토어 인앱 상품 등록(`lang_mn_1m`·`_3m`·`_1y`·`_life`, `all_1y`·`all_life`) — 출시할 때.
- Supabase `tts` 버킷의 옛 몽골어 음성 삭제.
- M6 디스크 정리.
- 회화 샘플·150편 톤 확인(리뷰 페이지).
