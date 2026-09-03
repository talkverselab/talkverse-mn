import 'package:flutter/material.dart';

import '../../core/display_settings.dart';
import '../../domain/models/dialogue.dart';
import '../../domain/models/flashcard.dart';
import '../../services/tts_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/sentence_view.dart';
import '../../widgets/ui_kit.dart';
import 'flashcard_session_screen.dart';

/// L2 다이얼로그 — 말풍선 챗 UI. A=Daniel(오른쪽) / B·C·D(왼쪽).
/// 성별 토글(학습자 성일치 어미 변환) · 전체 재생 · 플래시카드 전환.
class DialogueChatScreen extends StatefulWidget {
  const DialogueChatScreen({super.key, required this.dialogue});
  final Dialogue dialogue;

  @override
  State<DialogueChatScreen> createState() => _DialogueChatScreenState();
}

class _DialogueChatScreenState extends State<DialogueChatScreen> {
  bool _female = false; // 학습자 성별
  final Set<int> _revealed = {};
  bool _playing = false;
  int _playingIndex = -1;

  Color _fillFor(String speaker) {
    switch (speaker) {
      case 'A':
        return AppColors.sky;
      case 'B':
        return AppColors.mint;
      case 'C':
        return AppColors.peach;
      default:
        return AppColors.lilac;
    }
  }

  String _nameFor(String speaker) {
    switch (speaker) {
      case 'A':
        return _female ? 'Daniela' : 'Daniel';
      case 'B':
        return '상대';
      default:
        return speaker;
    }
  }

  // A = 학습자 성별, B = 여(기본), C/D 중립.
  IconData? _genderIcon(String speaker) {
    if (speaker == 'A') return _female ? Icons.female_rounded : Icons.male_rounded;
    if (speaker == 'B') return Icons.female_rounded;
    return null;
  }

  String _turnText(ChatTurn t) => t.view(_female).map((e) => e.surface).join(' ');

  /// 성별에 따라 바뀌는 토큰 인덱스 (남/여 surface 다른 곳).
  Set<int> _diffIdx(ChatTurn t) {
    final m = t.tokens, f = t.tokensFem;
    if (f == null || f.length != m.length) return const {};
    final s = <int>{};
    for (var i = 0; i < m.length; i++) {
      if (m[i].surface != f[i].surface) {
        s.add(i);
      }
    }
    return s;
  }

  Future<void> _playAll() async {
    if (_playing) {
      setState(() => _playing = false);
      await TtsService.instance.stop();
      return;
    }
    setState(() => _playing = true);
    final turns = widget.dialogue.turns;
    for (var i = 0; i < turns.length; i++) {
      if (!_playing || !mounted) break;
      setState(() => _playingIndex = i);
      await TtsService.instance.speak(_turnText(turns[i]));
      if (!_playing || !mounted) break;
      await Future.delayed(const Duration(milliseconds: 350));
    }
    if (mounted) {
      setState(() {
        _playing = false;
        _playingIndex = -1;
      });
    }
  }

  void _openFlashcards() {
    final d = widget.dialogue;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FlashcardSessionScreen(
        title: '${d.title} · 카드',
        fill: AppColors.sky,
        items: [
          for (final t in d.turns)
            FlashItem(tokens: t.view(_female), tts: _turnText(t), back: t.ko),
        ],
      ),
    ));
  }

  @override
  void dispose() {
    _playing = false;
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dialogue;
    return Scaffold(
      appBar: AppBar(
        title: Text(d.title, style: AppType.serif(17)),
        actions: [
          const ReadingToggleAction(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _GenderToggle(
              female: _female,
              onChanged: (v) => setState(() => _female = v),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          children: [
            _twistBanner(d),
            const SizedBox(height: 6),
            Center(
              child: Text('남/여 토글 → ‥‥ 밑줄 어미가 성별에 따라 바뀜',
                  style: AppType.sans(10.5, weight: FontWeight.w600, color: AppColors.inkFaint)),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < d.turns.length; i++) _bubble(d.turns[i], i),
          ],
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _twistBanner(Dialogue d) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 15, color: AppColors.inkFaint),
          const SizedBox(width: 6),
          Flexible(
            child: Text('${d.tone.ko} · 반전: ${d.twistLabel}',
                style: AppType.sans(11.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatTurn t, int i) {
    final isA = t.speaker == 'A';
    final tokens = t.view(_female);
    final fill = _fillFor(t.speaker);
    final revealed = _revealed.contains(i);
    final playing = _playingIndex == i;
    final gi = _genderIcon(t.speaker);
    final emph = _diffIdx(t);

    final bubble = GestureDetector(
      onTap: () => setState(() {
        revealed ? _revealed.remove(i) : _revealed.add(i);
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isA ? 18 : 5),
            bottomRight: Radius.circular(isA ? 5 : 18),
          ),
          border: Border.all(
            color: playing ? AppColors.amberDeep : AppColors.outline,
            width: playing ? 2.4 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SentenceText(tokens: tokens, size: 18, emphasize: emph)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => TtsService.instance.speak(_turnText(t)),
                  child: const Icon(Icons.volume_up_rounded, size: 19, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SentenceReading(tokens: tokens, size: 13, emphasize: emph),
            if (revealed) ...[
              const SizedBox(height: 7),
              Container(height: 1, color: AppColors.outline.withValues(alpha: 0.15)),
              const SizedBox(height: 7),
              Text(t.ko, style: AppType.sans(13, weight: FontWeight.w600, color: AppColors.ink, height: 1.35)),
            ],
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isA ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isA ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (gi != null) ...[
                  Icon(gi, size: 12, color: AppColors.inkFaint),
                  const SizedBox(width: 3),
                ],
                Text(_nameFor(t.speaker), style: AppType.sans(10.5, weight: FontWeight.w700, color: AppColors.inkFaint)),
                if (t.twist) ...[
                  const SizedBox(width: 4),
                  const Text('⚡', style: TextStyle(fontSize: 11)),
                ],
              ],
            ),
          ),
          bubble,
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline, width: 1.4)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: GhostButton(
                  label: _playing ? '정지' : '전체 재생',
                  icon: _playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  height: 50,
                  onTap: _playAll,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientButton(
                  label: '플래시카드',
                  icon: Icons.style_rounded,
                  height: 50,
                  onTap: _openFlashcards,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderToggle extends StatelessWidget {
  const _GenderToggle({required this.female, required this.onChanged});
  final bool female;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: () => onChanged(!female),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _seg(Icons.male_rounded, '남', !female),
            _seg(Icons.female_rounded, '여', female),
          ],
        ),
      ),
    );
  }

  Widget _seg(IconData icon, String label, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: on ? AppColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: on ? AppColors.inkOnDark : AppColors.inkFaint),
          const SizedBox(width: 3),
          Text(label,
              style: AppType.sans(12,
                  weight: FontWeight.w800, color: on ? AppColors.inkOnDark : AppColors.inkFaint)),
        ],
      ),
    );
  }
}
