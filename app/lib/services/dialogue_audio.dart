import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'content_sync.dart';
import 'learner_prefs.dart';
import 'tts_service.dart';

/// 회화 턴의 서버 녹음(mp4) — 일본어앱 `DialogueAudio` 방식(2026-11-22, 사용자 지시 「음성이 없는 건 TTS 로」).
///
/// 목록 = `GET …/art/mn/audio/manifest` → items[{episode, turn, voice(m·f), key, ms, text}], 파일 = base + key.
/// 녹음 글(이름 자리는 남 「Алекс」·여 「Эмма」)이 지금 대사와 같을 때만 녹음을 쓴다 — 대사를 고친 뒤 옛 녹음이 남아 있거나
/// 녹음이 없는 턴은 false 를 돌려주고, 부르는 쪽이 기존 음성(`TtsService`: 앱 번들 mp3 → 실시간 합성)으로 넘긴다.
/// 기기 내장 TTS 는 몽골어 목소리가 없는 기기가 대부분이라 쓰지 않는다(그 경우 무음).
class DialogueAudio {
  DialogueAudio._();
  static final DialogueAudio instance = DialogueAudio._();

  static const _names = {'m': 'Алекс', 'f': 'Эмма'};
  final Map<String, Map<int, Map<String, _Line>>> _index = {};
  Future<void>? _loading;
  AudioPlayer? _player;
  int _gen = 0;

  String get _manifestUrl => '${ContentSync.instance.base}/mn/audio/manifest';

  /// 목록을 한 번 받는다(실패하면 다음 재생 때 다시).
  Future<void> load() => _loading ??= _fetch();

  Future<void> _fetch() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.parse(_manifestUrl));
      req.headers.set(HttpHeaders.userAgentHeader, 'talkverse-mn/0.1');
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw 'HTTP ${res.statusCode}';
      final body = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
      final base = (body['base'] as String? ?? '${ContentSync.instance.base}/').replaceFirst(RegExp(r'/$'), '');
      for (final it in (body['items'] as List? ?? const [])) {
        final m = it as Map<String, dynamic>;
        final ep = m['episode'], turn = m['turn'], v = m['voice'], key = m['key'];
        if (ep is! String || turn is! int || v is! String || key is! String) continue;
        (_index[ep] ??= {})[turn] ??= {};
        _index[ep]![turn]![v] = _Line('$base/$key', (m['text'] as String?) ?? '', (m['ms'] as num?)?.toInt() ?? 0);
      }
    } catch (e) {
      debugPrint('DialogueAudio: 목록 실패 $e');
      _loading = null;
    } finally {
      client.close(force: true);
    }
  }

  static String _norm(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

  _Line? _line(String episodeId, int turn, String script) {
    final v = LearnerPrefs.isFemale ? 'f' : 'm';
    final l = _index[episodeId]?[turn]?[v];
    if (l == null) return null;
    return _norm(l.text) == _norm(script.replaceAll('{name}', _names[v]!)) ? l : null;
  }

  /// 녹음을 끝까지 재생한다. 녹음이 없거나 지금 대사와 다르거나 재생에 실패하면 false.
  Future<bool> play(String episodeId, int turn, {required String script, double rate = 1.0}) async {
    await load().timeout(const Duration(seconds: 15), onTimeout: () {});
    final l = _line(episodeId, turn, script);
    if (l == null) return false;
    final my = ++_gen;
    try {
      await TtsService.instance.stop();
      final p = _player ??= AudioPlayer();
      await p.stop();
      final done = p.onPlayerComplete.first;
      final f = ContentSync.instance.localFile(l.url);
      await p.play(f != null ? DeviceFileSource(f.path) : UrlSource(l.url)).timeout(const Duration(seconds: 12));
      if (rate != 1.0) await p.setPlaybackRate(rate);
      if (my != _gen) return true;
      await done.timeout(Duration(milliseconds: (l.ms / rate).round() + 6000), onTimeout: () {});
      return true;
    } catch (e) {
      debugPrint('DialogueAudio: 재생 실패 $episodeId $turn $e');
      return false;
    }
  }

  Future<void> stop() async {
    _gen++;
    try {
      await _player?.stop();
    } catch (_) {}
  }
}

class _Line {
  final String url, text;
  final int ms;
  const _Line(this.url, this.text, this.ms);
}
