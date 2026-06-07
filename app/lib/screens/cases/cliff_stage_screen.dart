import 'package:flutter/material.dart';

import '../../domain/models/cliff_stage.dart';
import '../../domain/models/lemma_entry.dart';
import '../../services/cliff_repository.dart';
import '../../services/tts_service.dart';

/// 한 cliff 단계의 lemma 전수 리스트.
class CliffStageScreen extends StatefulWidget {
  final CliffStage stage;
  const CliffStageScreen({super.key, required this.stage});

  @override
  State<CliffStageScreen> createState() => _CliffStageScreenState();
}

class _CliffStageScreenState extends State<CliffStageScreen> {
  late final Future<List<LemmaEntry>> _future =
      CliffRepository.instance.loadStage(widget.stage.id);

  String _filter = ''; // POS 필터 (빈 문자열 = 전체)

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final stage = widget.stage;
    return Scaffold(
      appBar: AppBar(
        title: Text(stage.title),
        backgroundColor: stage.accent.withValues(alpha: 0.10),
      ),
      body: FutureBuilder<List<LemmaEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('로드 실패: ${snap.error}'));
          }
          final all = snap.data ?? [];
          final filtered = _filter.isEmpty
              ? all
              : all.where((e) => e.pos == _filter).toList();
          final posCounts = <String, int>{};
          for (final e in all) {
            posCounts[e.pos] = (posCounts[e.pos] ?? 0) + 1;
          }
          return Column(
            children: [
              _StageBanner(stage: stage, total: all.length),
              _PosChips(
                posCounts: posCounts,
                current: _filter,
                onSelect: (p) => setState(() => _filter = p),
                accent: stage.accent,
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return _LemmaRow(entry: e, accent: stage.accent, theme: t);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StageBanner extends StatelessWidget {
  final CliffStage stage;
  final int total;
  const _StageBanner({required this.stage, required this.total});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      color: stage.accent.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stage.subtitle,
              style: t.textTheme.labelMedium?.copyWith(
                  color: stage.accent, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('$total 단어',
              style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(stage.description,
              style: t.textTheme.bodySmall?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

class _PosChips extends StatelessWidget {
  final Map<String, int> posCounts;
  final String current;
  final ValueChanged<String> onSelect;
  final Color accent;
  const _PosChips({
    required this.posCounts,
    required this.current,
    required this.onSelect,
    required this.accent,
  });
  @override
  Widget build(BuildContext context) {
    final order = ['NPRO','PREP','CONJ','PRCL','ADVB','ADJF','ADJS',
                   'VERB','INFN','PRED','NOUN','INTJ','NUMR','COMP'];
    final available = order.where(posCounts.containsKey).toList();
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          _chip(label: '전체', value: '', count: posCounts.values.fold(0, (a, b) => a + b), context: context),
          for (final p in available)
            _chip(label: posKo[p] ?? p, value: p, count: posCounts[p] ?? 0, context: context),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required String value,
    required int count,
    required BuildContext context,
  }) {
    final selected = current == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text('$label · $count'),
        selected: selected,
        onSelected: (_) => onSelect(value),
        selectedColor: accent.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: selected ? accent : null,
          fontWeight: selected ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}

class _LemmaRow extends StatelessWidget {
  final LemmaEntry entry;
  final Color accent;
  final ThemeData theme;
  const _LemmaRow({required this.entry, required this.accent, required this.theme});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: () => TtsService.instance.speak(entry.lemma),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: SizedBox(
        width: 44,
        child: Text(
          '${entry.rank}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      title: Text(
        entry.lemma,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${posKo[entry.pos] ?? entry.pos}  ·  '
        '${entry.count.toString().replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")} '
        '·  ${entry.cumPct.toStringAsFixed(2)}%',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Icon(Icons.volume_up_rounded, size: 18, color: accent.withValues(alpha: 0.7)),
    );
  }
}
