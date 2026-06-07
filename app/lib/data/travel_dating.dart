import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// 여행 데이팅앱 테마 문장 한 개 — 몽골어 + 한국어 + 독음 + 한국 화자용 문법 설명.
class TravelPhrase {
  final String mn; // 몽골어 (키릴)
  final String ko; // 한국어 뜻
  final String pron; // 한글 독음
  final String grammar; // 한국 화자용 문법 설명
  final String focus; // 핵심 문법 태그

  const TravelPhrase({
    required this.mn,
    required this.ko,
    required this.pron,
    required this.grammar,
    required this.focus,
  });

  factory TravelPhrase.fromJson(Map<String, dynamic> j) => TravelPhrase(
        mn: (j['mn'] ?? '') as String,
        ko: (j['ko'] ?? '') as String,
        pron: (j['pron'] ?? '') as String,
        grammar: (j['grammar'] ?? '') as String,
        focus: (j['focus'] ?? '') as String,
      );
}

/// 한 테마(시나리오) — 50문장 세트.
class TravelTheme {
  final String id;
  final String asset; // assets/data/travel/<id>.json
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const TravelTheme({
    required this.id,
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

/// 여행 데이팅 5테마 (각 50문장). 난이도: 첫인사 → 로맨스.
const travelThemes = <TravelTheme>[
  TravelTheme(
    id: 'arrival',
    asset: 'assets/data/travel/arrival.json',
    title: '도착 · 첫 인사',
    subtitle: '게스트하우스·투어에서 첫 만남 · 인사 · 이름 묻기',
    icon: Icons.waving_hand_rounded,
    accent: AppColors.sky,
  ),
  TravelTheme(
    id: 'self_intro',
    asset: 'assets/data/travel/self_intro.json',
    title: '자기소개 · 호감',
    subtitle: '어디서 왔는지 · 취미 · 칭찬 · 호감 표현',
    icon: Icons.person_rounded,
    accent: AppColors.mint,
  ),
  TravelTheme(
    id: 'ask_out',
    asset: 'assets/data/travel/ask_out.json',
    title: '데이트 신청 · 약속',
    subtitle: '커피 한잔 · 시간 · 장소 · 연락처 교환',
    icon: Icons.event_available_rounded,
    accent: AppColors.peach,
  ),
  TravelTheme(
    id: 'travel_together',
    asset: 'assets/data/travel/travel_together.json',
    title: '함께 여행',
    subtitle: '초원 · 게르 · 말 타기 · 교통 · 사진',
    icon: Icons.terrain_rounded,
    accent: AppColors.lilac,
  ),
  TravelTheme(
    id: 'romance',
    asset: 'assets/data/travel/romance.json',
    title: '감정 · 로맨스 · 작별',
    subtitle: '좋아해 · 보고 싶어 · 또 만나자 · 잘 가',
    icon: Icons.favorite_rounded,
    accent: AppColors.amberDeep,
  ),
];

/// 테마별 JSON 로더 + 메모이즈.
class TravelDatingRepository {
  TravelDatingRepository._();
  static final instance = TravelDatingRepository._();

  final Map<String, List<TravelPhrase>> _cache = {};

  Future<List<TravelPhrase>> load(TravelTheme theme) async {
    final cached = _cache[theme.id];
    if (cached != null) return cached;
    final raw = await rootBundle.loadString(theme.asset);
    final list = (jsonDecode(raw) as List)
        .map((e) => TravelPhrase.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache[theme.id] = list;
    return list;
  }
}
