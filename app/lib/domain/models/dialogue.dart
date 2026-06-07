import 'sentence.dart';

/// 챗 한 턴. speaker A=Daniel(학습자) / B=현지인 / C·D=가끔.
class ChatTurn {
  final String speaker; // 'A' | 'B' | 'C' | 'D'
  final List<Tok> tokens; // 기본 = 남성 학습자 버전
  final List<Tok>? tokensFem; // 여성 학습자일 때 대체 (성일치 어미 수정). null이면 동일
  final String ko; // 뜻
  final bool twist; // 반전 턴 표시

  const ChatTurn(
    this.speaker, {
    required this.tokens,
    this.tokensFem,
    required this.ko,
    this.twist = false,
  });

  List<Tok> view(bool learnerFemale) =>
      (learnerFemale && tokensFem != null) ? tokensFem! : tokens;
}

/// L2 회화 다이얼로그 1개 (8턴 기본, 에피소드 독립).
class Dialogue {
  final String id; // 'l2_d01'
  final String title; // 한국어 짧은 제목
  final String twistLabel; // 반전/카오스 종류 (예: '봇 의심')
  final DialogTone tone;
  final List<ChatTurn> turns;
  final bool challenge; // true = 6인칭 챌린지 셋

  const Dialogue({
    required this.id,
    required this.title,
    required this.twistLabel,
    required this.tone,
    required this.turns,
    this.challenge = false,
  });
}

enum DialogTone { positive, chaos, negative }

extension DialogToneStyle on DialogTone {
  String get ko {
    switch (this) {
      case DialogTone.positive:
        return '긍정·재미';
      case DialogTone.chaos:
        return '카오스·황당';
      case DialogTone.negative:
        return '부정·좌절';
    }
  }
}
