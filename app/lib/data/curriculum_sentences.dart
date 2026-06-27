import '../domain/models/sentence.dart';

/// 단계별 일상 예문 (여행 데이팅 테마). 색칠 규칙:
///   어간 = 잉크 / 어미 = 모음조화 색(masc=а о у / fem=э ө ү) · 동사=굵게 / 격 = 조사칩.
/// 몽골어는 성·인칭 변화가 없고 어순이 한국어와 같다(SOV).
const Map<String, List<Sentence>> curriculumSentences = {
  // ── 1단계 · 형용사 + 명사 (어순=한국어, 일치 없음) ───────────
  's1': [
    Sentence([
      Tok('Энэ', stemKo: '엥'),
      Tok('сайхан', stemKo: '세항'),
      Tok('өдөр', stemKo: '으드르'),
    ], ko: '이거 좋은 날이야.', note: '형용사 сайхан은 변하지 않고 명사 앞에 그대로 — 한국어 어순.'),
    Sentence([
      Tok('Чи', stemKo: '치'),
      Tok('сайн', stemKo: '셍'),
      Tok('найз', stemKo: '네즈'),
    ], ko: '너는 좋은 친구야.', note: '계사(이다) 없이 명사로 끝난다. "А는 B" 명사문.'),
    Sentence([
      Tok('Тэр', stemKo: '테르'),
      Tok('гоё', stemKo: '거요'),
      Tok('охин', stemKo: '어힝'),
    ], ko: '그녀는 예쁜 여자야.', note: '형용사 гоё도 무변화. 수식어→피수식어 순서.'),
    Sentence([
      Tok('Улаанбаатар', stemKo: '울란바토르'),
      Tok('том', stemKo: '텀'),
      Tok('хот', stemKo: '허트'),
    ], ko: '울란바토르는 큰 도시야.', note: '관사 없음 — 영어 a/the 부담 없음.'),
  ],

  // ── 2단계 · 모음조화 (같은 격, 모음 따라 어미 갈림) ──────────
  's2': [
    Sentence([
      Tok('Би', stemKo: '비'),
      Tok('ном', infl: 'ыг', stemKo: '넘', inflKo: '익', gender: Gender.masc, josa: '을/를'),
      Tok('унш', infl: 'сан', stemKo: '옹시', inflKo: '상', gender: Gender.masc, verb: true),
    ], ko: '나는 책을 읽었어.', note: '남성모음 단어 ном → а형 어미(-ыг, -сан). 색이 같으면 같은 조화.'),
    Sentence([
      Tok('Би', stemKo: '비'),
      Tok('гэр', infl: 'ийг', stemKo: '게르', inflKo: '익', gender: Gender.fem, josa: '을/를'),
      Tok('үз', infl: 'сэн', stemKo: '우즈', inflKo: '셍', gender: Gender.fem, verb: true),
    ], ko: '나는 집을 봤어.', note: '여성모음 단어 гэр → э형 어미(-ийг, -сэн). ном과 비교해 보세요.'),
    Sentence([
      Tok('Чи', stemKo: '치'),
      Tok('цай', infl: 'г', stemKo: '체', inflKo: '그', gender: Gender.neut, josa: '을/를'),
      Tok('уу', infl: 'сан', stemKo: '오', inflKo: '상', gender: Gender.masc, verb: true),
    ], ko: '너 차 마셨어?', note: '모음으로 끝나면 목적격은 짧은 -г.'),
  ],

  // ── 3단계 · 소유격 -ын/-ийн · 목적격 -ыг/-ийг ───────────────
  's3': [
    Sentence([
      Tok('Найз', infl: 'ын', stemKo: '네즈', inflKo: '잉', gender: Gender.masc, josa: '의'),
      Tok('нэр', stemKo: '네르'),
      Tok('хэн', stemKo: '헹'),
      Tok('бэ', stemKo: '베'),
    ], ko: '친구 이름이 뭐야?', note: '소유격 -ын(의). найз가 남성모음이라 -ын.'),
    Sentence([
      Tok('Чиний', stemKo: '치니'),
      Tok('нүд', stemKo: '누드'),
      Tok('гоё', stemKo: '거요'),
    ], ko: '네 눈 예뻐.', note: 'чи의 소유격은 불규칙 чиний(너의).'),
    Sentence([
      Tok('Би', stemKo: '비'),
      Tok('чамайг', stemKo: '차멕', josa: '을/를'),
      Tok('бод', infl: 'ож', stemKo: '버드', inflKo: '어즈', gender: Gender.masc, verb: true),
      Tok('байна', stemKo: '벵'),
    ], ko: '너 생각하고 있어.', note: 'чи의 목적격은 불규칙 чамайг(너를).'),
  ],

  // ── 4단계 · 여처격 -д/-т · 탈격 -аас/-ээс ───────────────────
  's4': [
    Sentence([
      Tok('Би', stemKo: '비'),
      Tok('Монгол', infl: 'д', stemKo: '몽골', inflKo: '드', gender: Gender.neut, josa: '에'),
      Tok('байна', stemKo: '벵'),
    ], ko: '나 몽골에 있어.', note: '여처격 -д(에/에게). 장소·도착점.'),
    Sentence([
      Tok('Би', stemKo: '비'),
      Tok('Солонгос', infl: 'оос', stemKo: '솔롱고스', inflKo: '어스', gender: Gender.masc, josa: '에서'),
      Tok('ир', infl: 'сэн', stemKo: '이르', inflKo: '셍', gender: Gender.fem, verb: true),
    ], ko: '나 한국에서 왔어.', note: '탈격: о로 끝나 -оос(원순조화). 출발점.'),
    Sentence([
      Tok('Чамд', stemKo: '참드', josa: '에게'),
      Tok('бэлэг', stemKo: '베렉'),
      Tok('өг', infl: 'нө', stemKo: '윽', inflKo: '느', gender: Gender.fem, verb: true),
    ], ko: '너에게 선물 줄게.', note: 'чи의 여격은 불규칙 чамд(너에게).'),
  ],

  // ── 5단계 · 도구격 -аар/-ээр · 공동격 -тай/-тэй ─────────────
  's5': [
    Sentence([
      Tok('Би', stemKo: '비'),
      Tok('машин', infl: 'аар', stemKo: '마싱', inflKo: '아르', gender: Gender.masc, josa: '로'),
      Tok('явна', stemKo: '얍나'),
    ], ko: '나 차로 갈게.', note: '도구격 -аар(로/타고). 수단·재료.'),
    Sentence([
      Tok('Би', stemKo: '비'),
      Tok('найз', infl: 'тай', stemKo: '네즈', inflKo: '테', gender: Gender.masc, josa: '와/과'),
      Tok('уулз', infl: 'на', stemKo: '올즈', inflKo: '나', gender: Gender.masc, verb: true),
    ], ko: '나 친구랑 만날 거야.', note: '공동격 -тай(와/과). 동반.'),
    Sentence([
      Tok('Чи', stemKo: '치'),
      Tok('зав', infl: 'тай', stemKo: '잡', inflKo: '테', gender: Gender.masc, josa: '있는'),
      Tok('юу', stemKo: '유오'),
    ], ko: '너 시간 있어?', note: '-тай는 "~가 있다(소유)"에도 쓰여 아주 흔하다.'),
  ],

  // ── 6단계 · 후치사 (дээр · дотор) ──────────────────────────
  's6': [
    Sentence([
      Tok('Ширээн', stemKo: '시렝'),
      Tok('дээр', stemKo: '데르', josa: '위에'),
      Tok('ном', stemKo: '넘'),
      Tok('байна', stemKo: '벵'),
    ], ko: '책상 위에 책 있어.', note: '후치사 дээр(위에) — 명사 뒤에. 한국어 "위"와 똑같다.'),
    Sentence([
      Tok('Гэр', infl: 'ийн', stemKo: '게르', inflKo: '잉', gender: Gender.fem, josa: '의'),
      Tok('дотор', stemKo: '더터르', josa: '안에'),
      Tok('дулаахан', stemKo: '도라항'),
    ], ko: '게르 안은 따뜻해.', note: '후치사 앞 명사는 보통 소유격(-ийн).'),
    Sentence([
      Tok('Миний', stemKo: '미니'),
      Tok('хажууд', stemKo: '하조드', josa: '옆에'),
      Tok('суу', stemKo: '소'),
    ], ko: '내 옆에 앉아.', note: 'хажууд(옆에)도 후치사. суу = 앉아(명령).'),
  ],

  // ── 7단계 · 동사 시제 (과거 -сан · 현재미래 -на) ────────────
  's7': [
    Sentence([
      Tok('Би', stemKo: '비'),
      Tok('хоол', stemKo: '헐'),
      Tok('ид', infl: 'сэн', stemKo: '이드', inflKo: '셍', gender: Gender.fem, verb: true),
    ], ko: '나 밥 먹었어.', note: '과거 -сэн. идэх가 여성모음이라 -сэн.'),
    Sentence([
      Tok('Би', stemKo: '비'),
      Tok('маргааш', stemKo: '마르가시'),
      Tok('яв', infl: 'на', stemKo: '얍', inflKo: '나', gender: Gender.masc, verb: true),
    ], ko: '나 내일 갈 거야.', note: '현재·미래 -на. явах가 남성모음이라 -на. 인칭 변화 없음.'),
    Sentence([
      Tok('Чи', stemKo: '치'),
      Tok('хаана', stemKo: '항'),
      Tok('амьдар', infl: 'даг', stemKo: '암다르', inflKo: '닥', gender: Gender.masc, verb: true),
      Tok('вэ', stemKo: '베'),
    ], ko: '너 어디 살아?', note: '습관·일반 -даг("늘 ~한다").'),
  ],
};

/// 단계별 핵심 포인트 (한국 화자용).
const Map<String, List<String>> grammarPoints = {
  'alpha': [
    '몽골 키릴 = 러시아 키릴 + Ө·Ү 두 글자(35자).',
    '모음조화: 남성 а о у ↔ 여성 э ө ү, 중성 и. 뒤따르는 어미가 이 그룹을 따라간다.',
    '발음 규칙은 외우지 말고 [소리]로 익힌다.',
  ],
  's1': [
    '어순이 한국어와 같다: 형용사 → 명사, 주어 → … → 동사(SOV).',
    '형용사는 변하지 않는다 — 성·수 일치 없음(러시아어 대비 공짜).',
    '계사(이다) 없이 명사로 문장이 끝난다.',
  ],
  's2': [
    '같은 격이라도 단어 모음에 따라 어미 모양이 갈린다(모음조화).',
    '남성모음(а о у) → а형, 여성모음(э ө ү) → э형 어미.',
    '이 앱의 색이 곧 모음조화 라임 — 같은 색끼리 묶어 익힌다.',
  ],
  's3': [
    '소유격 -ын/-ийн = 한국어 "~의".',
    '목적격 -ыг/-ийг(-г) = 한국어 "~을/를".',
    '대명사는 불규칙: чиний(너의), чамайг(너를).',
  ],
  's4': [
    '여처격 -д/-т = "~에/에게"(장소·시간·도착점).',
    '탈격 -аас/-ээс/-оос/-өөс = "~에서/부터"(출발점·비교).',
    'чамд(너에게)는 불규칙 여격.',
  ],
  's5': [
    '도구격 -аар/-ээр/-оор/-өөр = "~로/으로"(수단·재료·언어).',
    '공동격 -тай/-тэй/-той = "~와/과/랑"(동반).',
    '-тай는 "~가 있다(소유)"에도 쓰인다: завтай(시간 있는).',
  ],
  's6': [
    '전치사가 없고 명사 뒤에 후치사가 온다 — 한국어 "위·안·뒤"와 동일.',
    'дээр(위) · доор(아래) · дотор(안) · хойно(뒤) · өмнө(앞) · хажууд(옆).',
    '후치사 앞 명사는 보통 소유격으로.',
  ],
  's7': [
    '동사는 인칭 변화가 없다 — 주어가 바뀌어도 그대로(한국어처럼).',
    '과거 -сан/-сэн/-сон/-сөн, 현재·미래 -на/-нэ/-но/-нө, 습관 -даг.',
    '어미 모양은 모음조화로만 갈린다.',
  ],
  's8': [
    '하고 싶다 -маар/-мээр + байна.',
    '해도 된다·가능 болно, 필요 хэрэгтэй.',
    '정중한 부탁·당부 -аарай/-ээрэй.',
  ],
  's9': [
    '명사 부정 биш, 동사·형용사 부정 -гүй.',
    '판정 의문 첨사 уу/үү(모음조화), 의문사문 끝 вэ/бэ.',
    '의문사 хэн(누구)·юу(무엇)·хаана(어디)·хэзээ(언제).',
  ],
};
