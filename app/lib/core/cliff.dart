/// 몽골어 절벽 값 — 코드 한 곳(단어 화면·앱 소개가 함께 쓴다).
/// 2026-11-03 재산출: 누적 55/60/70/80%에 처음 닿는 순위. 격접사·어미는 각각 한 토큰, 용언은 기본형.
/// 단어 목록이 1,500개라 R5 는 1,500위에서 끊는다(일본어앱 2,000 대신 — 1,500개 누적 89.2%).
const List<int> kCliffs = [49, 71, 185, 522];
const int kWordCap = 1500;
const double kWordCapPct = 89.2;
const int kUnit = 20;

String regionOf(int rank) {
  for (var i = 0; i < kCliffs.length; i++) {
    if (rank <= kCliffs[i]) return 'R${i + 1}';
  }
  return 'R5';
}
