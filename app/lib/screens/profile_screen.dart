import 'package:flutter/material.dart';

import 'about_screen.dart';

import '../core/pane.dart';
import '../core/theme.dart';
import '../embed.dart';
import '../services/achievement_service.dart';
import '../services/ko_reading.dart';
import '../widgets/account_section.dart';
import '../widgets/legal_links.dart';
import '../widgets/learner_section.dart';
import '../widgets/spanish_decor.dart';
import '../core/l10n.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _resetProgress() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('학습 기록 초기화')),
        content: Text(tr('회화 진행·동사 기록·성과를 모두 지웁니다. 메모는 유지돼요.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('취소'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('초기화'), style: const TextStyle(color: AppColors.beni))),
        ],
      ),
    );
    if (ok != true) return;
    await appDb.delete(appDb.userProgress).go();
    await appDb.delete(appDb.verbProgress).go();
    await AchievementService.instance.reset();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('초기화 완료'))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('프로필'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.rojoDeep, AppColors.rojo],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gualda, width: 1.5),
            ),
            child: Row(
              children: [
                const TileBadge(text: 'MN', size: 60, color: AppColors.mongol),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('학습자'),
                        style: TextStyle(
                          color: AppColors.cal,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // 통합 앱(Talkverse)에서만: 다른 언어로(2026-11-09)
          if (switchLanguage != null) ...[
            _SettingsGroup(items: [
              _SettingItem(icon: Icons.swap_horiz, title: tr('다른 언어 배우기'), subtitle: tr('Talkverse 의 다른 언어로 이동'), onTap: switchLanguage!),
            ]),
            const SizedBox(height: 18),
          ],
          _SectionTitle(tr('계정')),
          const SizedBox(height: 8),
          const AccountSection(),
          const SizedBox(height: 18),
          _SectionTitle(tr('기록')),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(icon: Icons.delete_outline, title: tr('학습 기록 초기화'), subtitle: tr('회화·동사·성과 기록 삭제'), onTap: _resetProgress),
          ]),
          const SizedBox(height: 18),
          _SectionTitle(tr('학습자 프로필')),
          const SizedBox(height: 8),
          const LearnerSection(),
          const SizedBox(height: 18),
          _SectionTitle(tr('설정')),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: KoReadingPrefs.show,
            builder: (context, on, _) => _SettingsGroup(items: [
              _SettingItem(
                  icon: Icons.language,
                  title: tr('언어 / Language'),
                  subtitle: '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
                  onTap: AppLangPrefs.next),
              _SettingItem(
                  icon: Icons.text_fields,
                  title: tr('한글 독음'),
                  subtitle: on ? tr('표시 — 탭하면 숨김') : tr('미표시(기본) — 힘들어도 보지 않고 익혀보세요'),
                  onTap: () => KoReadingPrefs.toggle(context)),
            ]),
          ),
          const SizedBox(height: 16),
          _SectionTitle(tr('정보')),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(icon: Icons.info_outline, title: tr('앱 소개'), subtitle: tr('절벽구간 — 이 앱이 단어를 나누는 기준'), onTap: () => openPane(context, (_) => const AboutScreen())),
            _SettingItem(icon: Icons.tag, title: tr('앱 버전'), subtitle: '0.1.0 · alpha'),
            _SettingItem(icon: Icons.description_outlined, title: tr('이용약관'), subtitle: 'talkverse.uk/terms', onTap: () => Legal.open(Legal.terms)),
            _SettingItem(icon: Icons.privacy_tip_outlined, title: tr('개인정보처리방침'), subtitle: 'talkverse.uk/talkverse/mn/privacy', onTap: () => Legal.open(Legal.privacy)),
            _SettingItem(icon: Icons.copyright, title: tr('저작권'), subtitle: tr('몽골어유니버스 · 2026')),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: AppColors.tinta,
        letterSpacing: 2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cal,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gualda.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      // ListTile 의 잉크가 색칠한 Container 에 가려지지 않게 투명 Material 을 끼운다(Flutter 3.47 assert)
      child: Material(
        color: Colors.transparent,
        child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.rojo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.rojo, width: 0.8),
                ),
                child: Icon(items[i].icon, color: AppColors.rojo, size: 18),
              ),
              title: Text(items[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
              subtitle: Text(items[i].subtitle,
                  style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.rojo, size: 18),
            ),
            if (i < items.length - 1)
              Container(height: 0.5, color: AppColors.gualda.withValues(alpha: 0.3)),
          ],
        ],
      ),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  _SettingItem({required this.icon, required this.title, required this.subtitle, this.onTap});
}
