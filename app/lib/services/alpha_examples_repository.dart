import '../domain/models/lemma_entry.dart';
import 'cliff_repository.dart';

/// 글자별 예시어 — L1·L2의 *기능어 + 부사어*만, 첫 글자별로 묶음.
///
/// 전략적 선택(사용자): 대명사(NPRO)·동사(VERB/INFN)는 너무 뻔해 제외.
/// 전치사·접속사·불변화사(필러)·술어부사·부사 = "알면 바로 써먹는 고빈도어".
class AlphaExamplesRepository {
  AlphaExamplesRepository._();
  static final instance = AlphaExamplesRepository._();

  /// 기능어 + 부사어 POS.
  static const _pos = {'PREP', 'CONJ', 'PRCL', 'PRED', 'ADVB'};

  Map<String, List<LemmaEntry>>? _byInitial;

  /// 첫 글자(대문자) → 빈도순 예시 리스트.
  Future<Map<String, List<LemmaEntry>>> byInitial() async {
    final cached = _byInitial;
    if (cached != null) return cached;

    final l1 = await CliffRepository.instance.loadStage('l1');
    final l2 = await CliffRepository.instance.loadStage('l2');

    final out = <String, List<LemmaEntry>>{};
    for (final e in [...l1, ...l2]) {
      if (!_pos.contains(e.pos)) continue;
      if (e.lemma.isEmpty) continue;
      final key = e.lemma[0].toUpperCase(); // 키릴은 BMP 단일 코드유닛
      (out[key] ??= []).add(e);
    }
    for (final list in out.values) {
      list.sort((a, b) => a.rank.compareTo(b.rank)); // 빈도순
    }
    _byInitial = out;
    return out;
  }
}
