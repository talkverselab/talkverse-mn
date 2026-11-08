import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';

import '../core/cliff.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/mn_keyboard_guide.dart';

/// 키보드 연습 — 시스템 키보드(몽골어 입력기)로 절벽 단어를 따라 친다. 옛 아랍어앱 keyboard_screen 을 옮김
/// (사용자 지시 2026-11-08 "아랍어앱 키보드 좌우 반전해서 가져오기": 아랍어 오른쪽→왼쪽 입력을 몽골어 왼쪽→오른쪽으로).
/// 단어 = 단어장 1,500 중 공백 없는 2~8자, 순위순. 구간 칩으로 고른다. 대소문자는 가리지 않는다.
class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});
  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<WordRow> _all = const [];
  String _region = 'R1';
  int _i = 0;
  int _score = 0;
  bool? _correct;

  List<WordRow> get _words => _all.where((w) => regionOf(w.rank) == _region).toList();
  WordRow? get _cur => _words.isEmpty ? null : _words[_i % _words.length];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await (appDb.select(appDb.words)..orderBy([(w) => OrderingTerm.asc(w.rank)])).get();
    if (!mounted) return;
    setState(() => _all = [for (final w in rows) if (!w.word.contains(' ') && w.word.length >= 2 && w.word.length <= 8) w]);
    _speak();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    TtsService.instance.stop();
    super.dispose();
  }

  void _speak() {
    final w = _cur;
    if (w != null) TtsService.instance.speak(w.word);
  }

  static String _norm(String s) => s.trim().toLowerCase();

  void _onChanged(String v) {
    final w = _cur;
    if (w == null) return;
    final typed = _norm(v), target = _norm(w.word);
    if (typed.isEmpty || typed.length < target.length) {
      if (_correct != null) setState(() => _correct = null);
      return;
    }
    final ok = typed == target;
    setState(() => _correct = ok);
    if (ok) {
      _score++;
      _focus.unfocus();
    }
  }

  void _next() {
    setState(() {
      _i++;
      _controller.clear();
      _correct = null;
    });
    _speak();
    _focus.requestFocus();
  }

  void _pick(String r) {
    setState(() {
      _region = r;
      _i = 0;
      _controller.clear();
      _correct = null;
    });
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    final w = _cur;
    final border = _correct == true ? AppColors.matcha : (_correct == false ? AppColors.beni : AppColors.line);
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Text(tr('⌨️ 키보드 연습'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), tooltip: tr('키보드 설정법'), onPressed: () => showMnKeyboardGuide(context)),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(trf('점수 {0}', [_score]), style: const TextStyle(color: AppColors.matcha, fontSize: 15, fontWeight: FontWeight.w800))),
          ),
        ],
      ),
      body: SafeArea(
        child: _all.isEmpty
            ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Wrap(spacing: 6, children: [
                    for (final r in ['R1', 'R2', 'R3', 'R4', 'R5'])
                      ChoiceChip(label: Text(r), selected: _region == r, showCheckmark: false, onSelected: (_) => _pick(r)),
                  ]),
                  const SizedBox(height: 14),
                  if (w != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: AppColors.mongol, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Flexible(child: Text(w.word, textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w800))),
                          const SizedBox(width: 8),
                          IconButton(onPressed: _speak, icon: const Icon(Icons.volume_up), color: Colors.white, tooltip: tr('발음 듣기')),
                        ]),
                        if ((w.cefr ?? '').isNotEmpty) KoReadingText(w.cefr!, style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(w.meaningKo ?? '', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('#${w.rank} · ${_i % _words.length + 1}/${_words.length}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                      ]),
                    ),
                  const SizedBox(height: 16),
                  // 몽골어는 왼쪽 → 오른쪽 입력(아랍어앱의 오른쪽 → 왼쪽을 뒤집음)
                  TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _correct == false ? AppColors.beniDeep : AppColors.sumi),
                    decoration: InputDecoration(
                      hintText: tr('여기에 입력'),
                      filled: true,
                      fillColor: border.withValues(alpha: 0.06),
                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border, width: 2)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border, width: 2)),
                    ),
                    onChanged: _onChanged,
                    onSubmitted: _onChanged,
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => showMnKeyboardGuide(context),
                    icon: const Icon(Icons.info_outline, size: 16, color: AppColors.sumiLight),
                    label: Text(tr('몽골어 키보드가 없으면? 설정 방법 보기'), style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, decoration: TextDecoration.underline)),
                  ),
                  if (_correct != null)
                    Text(_correct! ? tr('🎉 정답!') : tr('❌ 다시 해 보세요'),
                        style: TextStyle(color: _correct! ? AppColors.matcha : AppColors.beniDeep, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.matcha, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: Text(_correct == true ? tr('다음 단어 →') : tr('건너뛰기'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ]),
              ),
      ),
    );
  }
}
