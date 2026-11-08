import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';

/// 몽골어(키릴) 키보드 설치 안내 — 옛 아랍어앱 arabic_keyboard_guide 를 옮김(사용자 지시 2026-11-08 "아랍어앱 키보드 좌우 반전해서 가져오기").
/// 아랍어는 오른쪽→왼쪽이었지만 몽골어는 왼쪽→오른쪽.
Future<void> showMnKeyboardGuide(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _Guide(),
    );

class _Guide extends StatelessWidget {
  const _Guide();

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(children: [
                Text(tr('키보드 설정'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppColors.muted), onPressed: () => Navigator.of(context).pop()),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(tr('시스템 키보드에 몽골어(Монгол) 입력기를 추가하면 앱 안에서 바로 키릴 문자를 칠 수 있어요. 러시아어 키보드에는 Ө·Ү 가 없으니 꼭 몽골어를 고르세요.'),
                  style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, height: 1.45)),
            ),
            const SizedBox(height: 12),
            TabBar(
              labelColor: AppColors.sumi,
              unselectedLabelColor: AppColors.muted,
              indicatorColor: AppColors.sumi,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              tabs: [Tab(text: tr('안드로이드')), Tab(text: tr('아이폰·아이패드'))],
            ),
            Expanded(
              child: TabBarView(children: [
                ListView(padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomInset(context)), children: [
                  _Section(tr('방법 1 — 삼성 키보드에 몽골어 추가'), [
                    tr('설정 앱 열기'),
                    tr('일반 → 삼성 키보드 설정'),
                    tr('언어 및 형식 → 입력 언어 관리 → +'),
                    tr('「몽골어」 검색 → 몽골어(Монгол) 다운로드'),
                    tr('목록에서 몽골어 켜기'),
                  ]),
                  const SizedBox(height: 16),
                  _Section(tr('방법 2 — Gboard(구글 키보드)'), [
                    tr('Play 스토어에서 Gboard 설치(이미 있으면 건너뛰기)'),
                    tr('Gboard 설정 → 언어 → 키보드 추가'),
                    tr('「몽골어」 선택 → 완료'),
                    tr('입력 칸을 눌러 키보드를 연 뒤 스페이스바 옆 🌐 를 길게 눌러 몽골어로 바꾸기'),
                  ]),
                  const SizedBox(height: 16),
                  const _Tips(),
                ]),
                ListView(padding: EdgeInsets.fromLTRB(20, 16, 20, 32 + bottomInset(context)), children: [
                  _Section(tr('기본 키보드에 몽골어 추가'), [
                    tr('설정 앱 열기'),
                    tr('일반 → 키보드 → 키보드'),
                    tr('새로운 키보드 추가'),
                    tr('「몽골어」 선택 → 완료'),
                  ]),
                  const SizedBox(height: 16),
                  _Section(tr('키보드 바꾸기'), [
                    tr('입력 칸을 눌러 키보드 열기'),
                    tr('스페이스바 왼쪽 🌐 를 누르면 다음 키보드로 바뀜'),
                    tr('길게 누르면 목록에서 바로 고를 수 있음'),
                  ]),
                  const SizedBox(height: 16),
                  const _Tips(),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

class _Tips extends StatelessWidget {
  const _Tips();
  @override
  Widget build(BuildContext context) => Column(children: [
        _Tip(tr('입력 방향: 몽골어는 한국어처럼 왼쪽 → 오른쪽으로 칩니다.')),
        const SizedBox(height: 10),
        _Tip(tr('대문자·소문자는 가리지 않아요. 글자만 맞으면 정답입니다.')),
      ]);
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> steps;
  const _Section(this.title, this.steps);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 10, top: 1),
                  decoration: const BoxDecoration(color: AppColors.sumi, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                Expanded(child: Text(steps[i], style: const TextStyle(fontSize: 13.5, color: AppColors.sumi, height: 1.4))),
              ]),
            ),
        ]),
      );
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.kin.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(right: 8, top: 1), child: Text('💡', style: TextStyle(fontSize: 16))),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.sumi, height: 1.4))),
        ]),
      );
}
