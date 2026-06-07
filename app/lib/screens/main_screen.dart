import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/ui_kit.dart';
import 'alphabet/cyrillic_alphabet_screen.dart';
import 'cases/cases_home_screen.dart';
import 'conversation/flashcards_home_screen.dart';
import 'curriculum/curriculum_home_screen.dart';
import 'travel/travel_dating_home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _tabs = <_TabDef>[
    _TabDef('홈', Icons.cottage_rounded, Icons.cottage_outlined),
    _TabDef('회화', Icons.style_rounded, Icons.style_outlined),
    _TabDef('문법', Icons.account_tree_rounded, Icons.account_tree_outlined),
    _TabDef('내 학습', Icons.person_rounded, Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            _HomeTab(onJump: (i) => setState(() => _index = i)),
            const FlashcardsHomeScreen(),
            const CurriculumHomeScreen(),
            const _LearningTab(),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        tabs: _tabs,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData active;
  final IconData inactive;
  const _TabDef(this.label, this.active, this.inactive);
}

// ─────────────────────────────────────────────────────────── 홈 탭

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onJump});
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        const SizedBox(height: 2),
        const BrandMark(),
        const SizedBox(height: 26),
        const Eyebrow('한국 화자를 위한 몽골어'),
        const SizedBox(height: 10),
        Text('여행에서 만나\n데이트까지 가는 몽골어',
            style: AppType.serif(28, height: 1.16)),
        const SizedBox(height: 12),
        Text(
          '몽골은 한국어와 같은 어순(SOV) · 격은 조사와 1:1 · 관사 없음 — 한국인에게 유리합니다. '
          '여행 데이팅 250문장을 문법 설명과 함께.',
          style: AppType.sans(14, color: AppColors.inkSoft, height: 1.55),
        ),
        const SizedBox(height: 22),
        _HeroCard(
          eyebrow: '여행 데이팅 회화',
          title: '테마별 50문장 × 5',
          subtitle: '첫인사·자기소개·데이트·여행·로맨스',
          fill: AppColors.peach,
          icon: Icons.favorite_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TravelDatingHomeScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _HeroCard(
          eyebrow: '문법 골격',
          title: '알파벳 + 9단계 커리큘럼',
          subtitle: '모음조화 · 격 · 동사 어미',
          fill: AppColors.mint,
          icon: Icons.account_tree_rounded,
          onTap: () => onJump(2),
        ),
        const SizedBox(height: 12),
        _HeroCard(
          eyebrow: '플래시카드',
          title: '문장으로 굴려 익히기',
          subtitle: '회화 문장을 카드로 · 뒤집기 + 발음',
          fill: AppColors.lilac,
          icon: Icons.style_rounded,
          onTap: () => onJump(1),
        ),
        const SizedBox(height: 12),
        _HeroCard(
          eyebrow: '몽골 키릴 35자',
          title: 'Аа · 소리부터',
          subtitle: '모음조화 · 가짜친구 · 몽골 자음 · Ө Ү',
          fill: AppColors.sky,
          icon: Icons.abc_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CyrillicAlphabetScreen()),
          ),
        ),
        const SizedBox(height: 26),
        const Eyebrow('왜 한국인에게 유리한가'),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: _StatCard(value: '1:1', label: '격 ↔ 조사', fill: AppColors.peach)),
            SizedBox(width: 12),
            Expanded(child: _StatCard(value: '자유', label: '어순', fill: AppColors.mint)),
            SizedBox(width: 12),
            Expanded(child: _StatCard(value: '0', label: '관사', fill: AppColors.sky)),
          ],
        ),
        const SizedBox(height: 14),
        OutlineCard(
          fill: AppColors.lilacLight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.hearing_rounded, color: AppColors.ink, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '진짜 보스는 모음조화·발음. 규칙은 단순하니 [소리]로 익히고 '
                  '나머지는 현지 듣기로 떠넘깁니다.',
                  style: AppType.sans(13, weight: FontWeight.w500, color: AppColors.ink, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.fill,
    required this.icon,
    required this.onTap,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color fill;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlineCard(
      fill: fill,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(),
                    style: AppType.sans(10.5, weight: FontWeight.w800, color: AppColors.inkSoft, spacing: 1.2)),
                const SizedBox(height: 8),
                Text(title, style: AppType.serif(20)),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: AppType.sans(12.5, weight: FontWeight.w500, color: AppColors.inkSoft, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.outline, width: 1.6),
            ),
            child: Icon(icon, color: AppColors.ink, size: 24),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.fill});
  final String value;
  final String label;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return OutlineCard(
      fill: fill,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: AppType.serif(22)),
          const SizedBox(height: 4),
          Text(label, style: AppType.sans(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────── 내 학습 / placeholder

class _LearningTab extends StatelessWidget {
  const _LearningTab();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('내 학습', style: AppType.serif(26)),
        const SizedBox(height: 6),
        Text('L1~L4 lemma 1,985개 · 빈도순 · POS 필터',
            style: AppType.sans(13, color: AppColors.inkSoft)),
        const SizedBox(height: 20),
        OutlineCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CasesHomeScreen()),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.outline, width: 1.4),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('단어 사전 · cliff browser', style: AppType.serif(16)),
                    const SizedBox(height: 3),
                    Text('격변화 5단계 절벽 탐색',
                        style: AppType.sans(12.5, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────── 하단 내비

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.tabs, required this.onTap});
  final int index;
  final List<_TabDef> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline, width: 1.4)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: _NavItem(
                    def: tabs[i],
                    selected: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.def, required this.selected, required this.onTap});
  final _TabDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.inkFaint;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.1 : 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: Icon(selected ? def.active : def.inactive, color: color, size: 25),
          ),
          const SizedBox(height: 4),
          Text(def.label,
              style: AppType.sans(10.5,
                  weight: selected ? FontWeight.w800 : FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
