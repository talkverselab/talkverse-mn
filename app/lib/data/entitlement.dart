import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 평생 이용권 — Talkverse 계정 이용권(lang 'mn', auth.talkverse.uk) 또는 이 기기에서 산·복원한 스토어 구매.
/// 2026-11-02 사용자 결정: 지금은 잠그는 것이 없다(모든 기능 무료). 잠금이 생기면 `premium` 으로 판단.
class Entitlement {
  Entitlement._();
  static const lang = 'mn';
  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
