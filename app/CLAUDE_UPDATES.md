# Claude 업데이트 메모 — mongolian_universe (mn)

> 기준 앱: chinese_universe(zh). 이식 세부 규격은 `zh/docs/PORTING_GUIDE_2026-09.md` 참고.
> 작성: 2026-09-05 (Claude Code 세션). 이후 변경은 git log 참고.

## 변경 이력
- `46413d3` (2026-09-03) 한글독음 전역 토글

## 변경 내용
- `core/display_settings.dart` 신설(ru 것에서 강세 부분 제외): `showReading` + `load()`/`toggleReading()` + `ReadingToggleAction`(`한` 원형 버튼). `main.dart`에서 `DisplaySettings.load()`.
- `widgets/sentence_view.dart`의 `SentenceReading`을 토글에 연결(전 화면 공용).
- `travel/travel_phrase_screen.dart`: 카드 앞/뒤의 `p.pron`(한글 독음) 두 곳 토글 연결.
- 토글 버튼 배치: 다이얼로그 챗 · 플래시카드 세션 · 여행 문장 앱바.

## 건드리지 않은 것
- 외우기 모드/외움 체크 미이식. 콘텐츠 무변경. `applicationId`는 `kr.mlab.mn` 그대로.
