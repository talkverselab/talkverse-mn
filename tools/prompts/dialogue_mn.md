# 몽골어 회화 Claude 초안 작성 규칙 (2026-11-08)

공통 원칙 https://talkverse.uk/talkverse/dialogue-rules/ · 몽골어 특이점 `docs/DIALOGUE.md` · 인물 `CHARACTERS.md`.
견본 6편: `app/assets/data/dialogues/R1/*/*.json` (먼저 두세 편을 읽고 형식·톤을 맞출 것).

## 파일
- 경로 `app/assets/data/dialogues/R<레벨>/<주제>/<편id>.json`, 들여쓰기 1칸 JSON, 끝에 줄바꿈.
- 편 칸: `id region island kind draft(true) purpose[] domain[] title(한국어) emoji scene(한국어 한 줄) speakers{A:"{name}", B:…, C:…} register(polite|casual|chat|mixed) twist(반전 턴 번호) twist_type flags[] expressions[] goal turns[]`.
- 턴 칸: `num speaker tl(몽골어 키릴) rd("" — 검사기가 채움) ko note(핵심 낱말 한 줄, 「몽골어 = 뜻」) tags[] new[] emotion` (+ 감정이 바뀌는 턴만 `segs`).
- 다 쓰면 `python3 tools/check_dialogues.py --fix-rd <자기 파일들>` → 오류 0 까지 고친다.

## 분량
- 턴 수 R1 6~8 · R2 8~12 · R3 12~16. 한 턴 낱말 수 R1 ≤7 · R2 ≤9 · R3 ≤12(키릴 낱말 기준). 1~2문장.
- R1 은 짧고 쉬운 문형, R2 는 이유·조건·과거 이야기, R3 는 감정·의견·완곡 표현까지.
- 1단어 턴은 반전 턴·마지막 턴·표현 풀 한마디(「За」「Тийм үү?」 등)만.

## 톤 (가장 중요)
- 몽골 사람이 실제로 쓰는 짧은 구어. 교과서체·번역투·설명 대사·다짐/감사로 끝내기 금지.
- 편마다 입에 남는 한 줄 + 코믹한 킥 1개 이상. 반전은 본론 후반에 1회(`twist` 턴).
- 표현 풀 `data/expressions/mn_top_expressions.csv` 에서 편마다 2개 이상(`expressions` 칸에 실제로 쓴 것을 적는다).
- 연애·플러팅은 썸까지(12+), 편마다 심쿵 한 줄(마음을 들키는 말·말끝 흐리기·여운, emotion shy/gentle). **여성이 먼저 다가가는 편을 더 많이.**
- SNS·채팅·데이팅앱 장면을 많이(kind `chat`, register `chat`, 이모지 가능).
- 말투: 처음 보는 사이·가게·일 = Та(존대), 친구·연인 = Чи(반말). 가까워지는 전환 장면도 가끔. 한국어 번역도 같은 말투.
- A 는 학습자 `{name}`(국적 비고정, 성별이 드러나지 않게 — 한국어 번역에 오빠·누나·형 금지). 이름이 필요하면 `{name}`.
- 실존 인물·가게·브랜드·작품 이름 금지(지어낸 이름만). 술은 드물게(flags `alcohol`).

## 인물
- 사랑: Сараа(사라, 20대 초 대학생·주말 초원 투어 가이드, 밝고 당참·말 빠름) — 기본 B.
- 친구: Номин(노민, 바리스타, 쿨·정색 농담) · Тэмүүлэн(테뮬렌, 마두금 록 밴드, 낭만파).
- 여행: Бат(바트, 투어 승합차 기사, 무뚝뚝하지만 은근히 웃김, 보온병).
- 그 밖(점원·기사·주인·직장 동료·상사 등)은 speakers 값에 한국어 역할 이름(「점원」「상사」).

## 반전 유형(twist_type, 편마다 하나)
chaos(일이 걷잡을 수 없이 커짐) · slip(말실수·오해) · reveal(의외 사실) · emotion(심쿵·감정) · ignore(읽씹).
받은 배정표의 개수를 지킨다. chaos 예: 「네」만 했더니 봉투·적립·1+1 / 「아무거나」에 메뉴 전부 / 하트를 단톡방에 / 셀카에 행인·강아지까지.

## 감정(emotion) — 턴마다
neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle.
neutral 만 쓰지 말 것(편의 절반 넘으면 검사기 오류). 점원 안내 polite, 츳코미 tsukkomi, 심쿵 shy·gentle.
한 턴에서 감정이 바뀌면 `segs: [[감정, 본문], …]`, 이어 붙이면 tl 과 같아야 한다(4글자 미만 조각 만들지 말 것).

## 몽골어
- 할흐 표준, 키릴. 모음조화·격어미를 정확히(-д/-т, -аас/-ээс/-оос/-өөс, -тай/-тэй/-той …). 확실하지 않은 표현은 더 쉬운 확실한 표현으로.
- 의문: уу/үү/юу/юү, вэ/бэ 구분. 명령·권유: -аарай, -ъя/-ье, -яарай.
