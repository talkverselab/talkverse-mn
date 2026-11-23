import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_service.dart';

/// 이용권 — Talkverse 계정 이용권(lang 'mn', auth.talkverse.uk) 또는 이 기기에서 산·복원한 스토어 구매(lang_mn_* · all_*).
/// 무료·유료 범위 = `~/talkverse/PAYWALL_SPEC.md` §2(2026-11-23 사용자 「1 2 모두 진행」, 범위는 uk 의 정함):
/// 무료 = 커리큘럼 1단계·회화 1단계(R0·R1)·글자/발음/단어 기본·문법 앞 2스텝·언어감각 1급. 유료 = 그 밖. 잠긴 곳은 숨기지 않고 자물쇠 → 결제 화면.
class Entitlement {
  Entitlement._();
  static const lang = 'mn';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  /// 이용권이 바뀌면(구매·복원·로그인) 화면을 다시 그리게.
  static Listenable get changes => Listenable.merge([Purchase.owned, Account.user]);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);

  /// 회화 편이 무료인가 — 회화 1단계(R0·R1)와 옛 이야기(L1), 또는 서버가 무료로 둔 커리큘럼 단계에 든 편.
  static bool dialogueFree(Dialogue d) =>
      const {'R0', 'R1', 'L1'}.contains(d.region) ||
      (CurriculumStages.instance.stages?.any((s) => s.free && s.dialogueIds.contains(d.id)) ?? false);

  /// 회화 레벨(R*) 묶음이 무료인가(목록 머리 자물쇠용).
  static bool regionFree(String region) => const {'R0', 'R1', 'L1'}.contains(region);

  /// 문법 스텝·언어감각 급의 무료 한도(서버 커리큘럼 JSON freeSteps·freeSenseLevels, 없으면 2·1). [index] 는 0부터.
  static bool grammarStepFree(int index) => index < CurriculumStages.instance.freeSteps;
  static bool senseLevelFree(int index) => index < CurriculumStages.instance.freeSenseLevels;

  /// 열려 있으면 [go], 잠겼으면 결제 화면 → 산 뒤 열리면 [go].
  static Future<void> guard(BuildContext context, bool free, VoidCallback go) async {
    if (free || premium) return go();
    await showPaywall(context);
    if (premium && context.mounted) go();
  }
}

/// 잠긴 칸 표시(자물쇠).
class LockBadge extends StatelessWidget {
  final double size;
  const LockBadge({super.key, this.size = 18});
  @override
  Widget build(BuildContext context) => Icon(Icons.lock_outline, size: size, color: const Color(0xFF8A94A6));
}
