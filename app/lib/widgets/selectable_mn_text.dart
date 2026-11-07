import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../data/mn_affixes.dart';
import '../services/word_lookup.dart';
import 'affix_sheet.dart';
import 'lemma_chips.dart';

/// 회화 문장 — 낱말을 레마로 찾아 **탭하면 단어창**, **길게 누르면 접사 시트**(일본어앱 SelectableJaText 의 몽골어판, 사용자 지시 2026-11-07).
/// 단어장에 있는 낱말은 밑줄(ai). 단어장에 없어도 접사가 분석되면 탭 → 접사 시트.
class SelectableMnText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final List<(String, String, String)> lemmas;
  const SelectableMnText({super.key, required this.text, required this.style, this.lemmas = const []});

  @override
  State<SelectableMnText> createState() => _SelectableMnTextState();
}

class _SelectableMnTextState extends State<SelectableMnText> {
  static final _word = RegExp(r'[\p{L}\p{M}-]+', unicode: true);
  Map<String, WordRow> _hits = const {};

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  @override
  void didUpdateWidget(SelectableMnText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _lookup();
  }

  Future<void> _lookup() async {
    final text = widget.text;
    final hits = await wordsInText(text, lemmas: widget.lemmas);
    if (mounted && text == widget.text) setState(() => _hits = hits);
  }

  InlineSpan _span(BuildContext context, String w) {
    final row = _hits[w];
    final affix = analyzeWord(w);
    void showAffix() => AffixSheet.show(context, affix!.affix, hit: affix);
    if (row == null && affix == null) return TextSpan(text: w);
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: row != null ? () => showWordSheet(context, row) : showAffix,
        onLongPress: affix == null ? null : showAffix,
        child: Text(
          w,
          style: row == null
              ? widget.style
              : widget.style.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.ai.withValues(alpha: 0.55),
                  decorationThickness: 1.4,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _word.allMatches(widget.text)) {
      if (m.start > at) spans.add(TextSpan(text: widget.text.substring(at, m.start)));
      spans.add(_span(context, m.group(0)!));
      at = m.end;
    }
    if (at < widget.text.length) spans.add(TextSpan(text: widget.text.substring(at)));
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
