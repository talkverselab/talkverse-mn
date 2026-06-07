import 'package:flutter/material.dart';

import '../../data/travel_dating.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// 한 테마의 50문장 학습 — 카드 넘기기 + 탭하면 뒤집어 문법 설명.
class TravelPhraseScreen extends StatefulWidget {
  const TravelPhraseScreen({super.key, required this.theme});
  final TravelTheme theme;

  @override
  State<TravelPhraseScreen> createState() => _TravelPhraseScreenState();
}

class _TravelPhraseScreenState extends State<TravelPhraseScreen> {
  final _pc = PageController();
  List<TravelPhrase> _items = const [];
  int _i = 0;
  bool _back = false;

  @override
  void initState() {
    super.initState();
    TravelDatingRepository.instance.load(widget.theme).then((list) {
      if (!mounted) return;
      setState(() => _items = list);
      if (list.isNotEmpty) TtsService.instance.speak(list.first.mn);
    });
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.theme.accent;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(widget.theme.title, style: AppType.serif(18)),
        centerTitle: true,
        actions: [
          if (_items.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${_i + 1}/${_items.length}',
                    style: AppType.sans(13, weight: FontWeight.w700, color: AppColors.inkSoft)),
              ),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pc,
                      itemCount: _items.length,
                      onPageChanged: (i) {
                        setState(() {
                          _i = i;
                          _back = false;
                        });
                        TtsService.instance.speak(_items[i].mn);
                      },
                      itemBuilder: (context, i) => _card(_items[i], c),
                    ),
                  ),
                  _bottomBar(c),
                ],
              ),
            ),
    );
  }

  Widget _card(TravelPhrase p, Color c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: GestureDetector(
        onTap: () => setState(() => _back = !_back),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.withValues(alpha: 0.5), width: 2),
          ),
          child: SingleChildScrollView(
            child: _back ? _backFace(p, c) : _frontFace(p, c),
          ),
        ),
      ),
    );
  }

  Widget _frontFace(TravelPhrase p, Color c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Tag2(text: p.focus, color: c),
            const Spacer(),
            GestureDetector(
              onTap: () => TtsService.instance.speak(p.mn),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(Icons.volume_up_rounded, color: c, size: 23),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(p.mn, style: AppType.serif(28, weight: FontWeight.w700, height: 1.25)),
        const SizedBox(height: 12),
        Text(p.pron, style: AppType.sans(15, weight: FontWeight.w500, color: AppColors.inkSoft)),
        const SizedBox(height: 28),
        Row(
          children: [
            Icon(Icons.touch_app_outlined, size: 15, color: AppColors.inkFaint),
            const SizedBox(width: 6),
            Text('탭하면 뜻 · 문법 설명',
                style: AppType.sans(12, weight: FontWeight.w600, color: AppColors.inkFaint)),
          ],
        ),
      ],
    );
  }

  Widget _backFace(TravelPhrase p, Color c) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(p.mn, style: AppType.serif(19, weight: FontWeight.w700))),
            GestureDetector(
              onTap: () => TtsService.instance.speak(p.mn),
              child: Icon(Icons.volume_up_rounded, color: c, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(p.pron, style: AppType.sans(13, color: AppColors.inkFaint)),
        const Divider(height: 24, color: AppColors.line),
        Text(p.ko, style: AppType.serif(20, weight: FontWeight.w600, height: 1.3)),
        const SizedBox(height: 16),
        Tag2(text: p.focus, color: c),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 17, color: c),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p.grammar,
                    style: AppType.sans(13.5, weight: FontWeight.w500, color: AppColors.ink, height: 1.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(Color c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left_rounded, () => _go(-1)),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _back = !_back),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: c.withValues(alpha: 0.4), width: 1.4),
                ),
                child: Text(_back ? '문장 보기' : '뜻 · 문법 보기',
                    style: AppType.sans(14, weight: FontWeight.w800, color: AppColors.ink)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _navBtn(Icons.chevron_right_rounded, () => _go(1)),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.outline, width: 1.4),
        ),
        child: Icon(icon, color: AppColors.ink),
      ),
    );
  }

  void _go(int delta) {
    final n = _items.length;
    if (n == 0) return;
    final next = (_i + delta).clamp(0, n - 1);
    _pc.animateToPage(next,
        duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }
}

/// 작은 문법 태그 칩.
class Tag2 extends StatelessWidget {
  const Tag2({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text,
          style: AppType.sans(11.5, weight: FontWeight.w800, color: AppColors.ink)),
    );
  }
}
