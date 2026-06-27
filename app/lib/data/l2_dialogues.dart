import '../domain/models/dialogue.dart';
import '../domain/models/sentence.dart';

/// 여행 데이팅 챗 다이얼로그 — 짧은 턴, 에피소드 독립.
/// A = 학습자(한국 여행자), B = 현지인. 톤: 담백·위트. 매 다이얼로그 반전 1회.
const l2Dialogues = <Dialogue>[
  // ── D01 · 게스트하우스 첫 만남 (반전=같은 투어) ────────────
  Dialogue(
    id: 'mn_d01',
    title: '게스트하우스 첫 만남',
    twistLabel: '같은 투어',
    tone: DialogTone.positive,
    turns: [
      ChatTurn('B', ko: '안녕하세요?', tokens: [
        Tok('Сайн', stemKo: '셍'),
        Tok('байна', stemKo: '벵'),
        Tok('уу?', stemKo: '오'),
      ]),
      ChatTurn('A', ko: '안녕하세요? 저 한국에서 왔어요.', tokens: [
        Tok('Сайн', stemKo: '셍'),
        Tok('уу?', stemKo: '오'),
        Tok('Би', stemKo: '비'),
        Tok('Солонгосоос', stemKo: '솔롱고소스', josa: '에서'),
        Tok('ирсэн.', stemKo: '이르셍'),
      ]),
      ChatTurn('B', ko: '어서 와요! 이름이 뭐예요?', tokens: [
        Tok('Тавтай', stemKo: '탑테'),
        Tok('морил!', stemKo: '머릴'),
        Tok('Таны', stemKo: '타니'),
        Tok('нэр', stemKo: '네르'),
        Tok('хэн', stemKo: '헹'),
        Tok('бэ?', stemKo: '베'),
      ]),
      ChatTurn('A', ko: '저는 민이에요. 당신은요?', tokens: [
        Tok('Намайг', stemKo: '나멕'),
        Tok('Мин', stemKo: '민'),
        Tok('гэдэг.', stemKo: '게덱'),
        Tok('Чиний', stemKo: '치니'),
        Tok('нэр?', stemKo: '네르'),
      ]),
      ChatTurn('B', ko: '저는 사라예요. 몽골 처음이에요?', tokens: [
        Tok('Намайг', stemKo: '나멕'),
        Tok('Сараа', stemKo: '사라'),
        Tok('гэдэг.', stemKo: '게덱'),
        Tok('Монголд', stemKo: '몽골드', josa: '에'),
        Tok('анх', stemKo: '앙흐'),
        Tok('удаа', stemKo: '오다'),
        Tok('юу?', stemKo: '유오'),
      ]),
      ChatTurn('A', ko: '네. 내일 초원에 가요.', tokens: [
        Tok('Тийм.', stemKo: '팀'),
        Tok('Маргааш', stemKo: '마르가시'),
        Tok('талд', stemKo: '탈드', josa: '에'),
        Tok('явна.', stemKo: '얍나'),
      ]),
      ChatTurn('B',
          twist: true,
          ko: '정말요? 저도 그 투어 가요!',
          tokens: [
            Tok('Үнэхээр?', stemKo: '우네헤르'),
            Tok('Би', stemKo: '비'),
            Tok('ч', stemKo: '치'),
            Tok('бас', stemKo: '바스'),
            Tok('тэр', stemKo: '테르'),
            Tok('аялалд', stemKo: '아야랄드', josa: '에'),
            Tok('явна!', stemKo: '얍나'),
          ]),
      ChatTurn('A', ko: '와, 그럼 같이 가요!', tokens: [
        Tok('Хөөх,', stemKo: '흐흐'),
        Tok('тэгвэл', stemKo: '테그벨'),
        Tok('хамт', stemKo: '함트'),
        Tok('явъя!', stemKo: '야뱌'),
      ]),
    ],
  ),

  // ── D02 · 데이트 약속 (반전=말 무서워함) ───────────────────
  Dialogue(
    id: 'mn_d02',
    title: '초원 데이트 약속',
    twistLabel: '말 무서워함',
    tone: DialogTone.positive,
    turns: [
      ChatTurn('A', ko: '안녕? 내일 시간 있어?', tokens: [
        Tok('Сайн', stemKo: '셍'),
        Tok('уу?', stemKo: '오'),
        Tok('Маргааш', stemKo: '마르가시'),
        Tok('завтай', stemKo: '잡테'),
        Tok('юу?', stemKo: '유오'),
      ]),
      ChatTurn('B', ko: '있어. 뭐 할 건데?', tokens: [
        Tok('Завтай.', stemKo: '잡테'),
        Tok('Юу', stemKo: '유오'),
        Tok('хийх', stemKo: '히흐'),
        Tok('вэ?', stemKo: '베'),
      ]),
      ChatTurn('A', ko: '같이 말 타자.', tokens: [
        Tok('Хамт', stemKo: '함트'),
        Tok('морь', stemKo: '머르'),
        Tok('унъя.', stemKo: '오냐'),
      ]),
      ChatTurn('B',
          twist: true,
          ko: '나 말 좀 무서워해.',
          tokens: [
            Tok('Би', stemKo: '비'),
            Tok('мориноос', stemKo: '머리너스', josa: '을'),
            Tok('жаахан', stemKo: '자항'),
            Tok('айдаг.', stemKo: '에닥'),
          ]),
      ChatTurn('A', ko: '무서워 마, 내가 옆에 있을게.', tokens: [
        Tok('Бүү', stemKo: '부'),
        Tok('ай,', stemKo: '에'),
        Tok('би', stemKo: '비'),
        Tok('хажууд', stemKo: '하조드', josa: '옆에'),
        Tok('чинь', stemKo: '칭'),
        Tok('байна.', stemKo: '벵'),
      ]),
      ChatTurn('B', ko: '좋아, 너랑이면 갈게.', tokens: [
        Tok('Зүгээр,', stemKo: '주게르'),
        Tok('чамтай', stemKo: '참테', josa: '와'),
        Tok('бол', stemKo: '벌'),
        Tok('явъя.', stemKo: '야뱌'),
      ]),
      ChatTurn('A', ko: '이따 같이 사진도 찍자.', tokens: [
        Tok('Дараа', stemKo: '다라'),
        Tok('нь', stemKo: '느'),
        Tok('хамт', stemKo: '함트'),
        Tok('зураг', stemKo: '조락'),
        Tok('авъя.', stemKo: '아뱌'),
      ]),
      ChatTurn('B', ko: '좋아! 전화번호 줘.', tokens: [
        Tok('Болно!', stemKo: '벌너'),
        Tok('Утасны', stemKo: '오타스니'),
        Tok('дугаараа', stemKo: '도가라', josa: '를'),
        Tok('өгөөч.', stemKo: '으그치'),
      ]),
    ],
  ),
];
