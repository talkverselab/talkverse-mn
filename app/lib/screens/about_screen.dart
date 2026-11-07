import 'package:flutter/material.dart';

import '../core/cliff.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../widgets/spanish_decor.dart';

/// 앱 소개 — 이 앱의 뼈대인 **절벽구간**을 설명한다(일본어앱 about_screen 과 같은 구조, 사용자 지시 2026-11-07).
/// 몽골어는 문자 기준 절벽이 없어 1. 단어 기준  2. 산출 방식  3. 앱에서 쓰는 곳. 숫자 = `core/cliff.dart`.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        appBar: AppBar(
          title: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(tr('앱 소개'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(tr('절벽구간 — 이 앱이 단어를 나누는 기준'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
          ]),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
          children: [
            _Lead(tr('대사에서 자주 나오는 말은 아주 적습니다. 처음 49개 단어가 대사의 55%를 차지하고, 522개면 80%입니다. 그 뒤로는 단어를 아무리 더 외워도 들리는 비율이 조금씩만 오릅니다 — 이 급한 경사를 「절벽」이라 부르고, 절벽이 끝나는 자리마다 구간(R1~R5)을 나눕니다.')),
            const SizedBox(height: 18),
            _H(tr('1. 단어 기준')),
            const _CliffTable(),
            const SizedBox(height: 18),
            _H(tr('2. 산출 방식')),
            _Para(tr('말뭉치 — 공개 자막 34편, 약 27만 토큰. 몽골에서 만든 영화·드라마 대사 자료가 없어 대부분 번역 자막이고, 형태소는 규칙으로 근사해 나눴습니다. 신뢰도가 낮은 값이라 더 큰 말뭉치가 생기면 다시 산출합니다.')),
            _Para(tr('빈도 — 각 단어의 등장 횟수 ÷ 전체 등장 횟수. 가중치 없음.')),
            _Para(tr('구간 — 빈도순으로 누적해 55%·60%·70%·80%에 처음 닿는 순위가 R1·R2·R3·R4 의 끝. 80% 밖은 R5. 이 네 비율은 Talkverse 언어 앱 공통 기준입니다.')),
            _Para(tr('단어 목록 — 앱의 1,500어는 이 경계에 맞춰 따로 정리한 학습용 목록이라, 순위가 말뭉치 순위와 꼭 같지는 않습니다.')),
            const SizedBox(height: 18),
            _H(tr('3. 앱에서 쓰는 곳')),
            _Para(tr('절벽 단어 — R1→R5 순서로 20어씩 한 단원. 「회화 단어 포함」을 누르면 회화에 나오는 말 중 목록 밖 단어가 「회화」 구간으로 뒤에 붙습니다.')),
            _Para(tr('회화 — 몽골어 회화는 R3 까지 만듭니다.')),
            const SizedBox(height: 24),
            const BrushDivider(),
            const SizedBox(height: 10),
            Center(child: Text(tr('절벽 v2 · 단어 2026-11-03'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 11, letterSpacing: 2))),
          ],
        ),
      );
}

class _Lead extends StatelessWidget {
  final String text;
  const _Lead(this.text);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.washiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: const TextStyle(color: AppColors.sumi, fontSize: 14, height: 1.6)),
      );
}

class _H extends StatelessWidget {
  final String text;
  const _H(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
      );
}

class _Para extends StatelessWidget {
  final String text;
  const _Para(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: AppColors.sumiLight, fontSize: 13, height: 1.55)),
      );
}

/// 구간표 — R1~R5: 순위 범위 · 개수 · 누적 %. 막대는 구간 등폭 5칸.
class _CliffTable extends StatelessWidget {
  const _CliffTable();

  static const _pct = ['55%', '60%', '70%', '80%'];
  static const _colors = [AppColors.beni, AppColors.beniLight, AppColors.kinDeep, AppColors.matcha, AppColors.muted];

  @override
  Widget build(BuildContext context) {
    final unit = tr('어');
    final rows = <(String, String, String, String)>[];
    var prev = 0;
    for (var i = 0; i < 4; i++) {
      final end = kCliffs[i];
      rows.add(('R${i + 1}', '${prev + 1}-$end', '${end - prev}$unit', _pct[i]));
      prev = end;
    }
    rows.add(('R5', '${prev + 1}-$kWordCap', '${kWordCap - prev}$unit', '$kWordCapPct%'));
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(children: [
            for (var i = 0; i < 5; i++)
              Expanded(
                child: Container(
                  height: 10,
                  margin: EdgeInsets.only(right: i < 4 ? 2 : 0),
                  decoration: BoxDecoration(color: _colors[i], borderRadius: BorderRadius.circular(2)),
                ),
              ),
          ]),
        ),
        for (var i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.line, width: i == 0 ? 0 : 0.6))),
            child: Row(children: [
              Container(
                width: 30,
                padding: const EdgeInsets.symmetric(vertical: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _colors[i], borderRadius: BorderRadius.circular(2)),
                child: Text(rows[i].$1, style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(rows[i].$2, style: const TextStyle(color: AppColors.sumi, fontSize: 13, fontWeight: FontWeight.w700))),
              SizedBox(width: 56, child: Text(rows[i].$3, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.sumiLight, fontSize: 12))),
              SizedBox(
                width: 84,
                child: Text(trf('누적 {0}', [rows[i].$4]), textAlign: TextAlign.right, style: const TextStyle(color: AppColors.sumi, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: Text(tr('격접사·어미도 각각 한 단어로 세고, 용언은 기본형으로 셉니다. R5 는 1,500위에서 끊습니다(누적 89.2%).'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 11, height: 1.5)),
        ),
      ]),
    );
  }
}
