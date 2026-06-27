import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

/// 몽골어 음성 — Azure Neural(mn-MN) 우선, 1초 지연 후 재생.
///
/// Azure 키가 있으면(`--dart-define=AZURE_SPEECH_KEY=...`) Azure REST로 합성해
/// mn-MN-YesuiNeural 목소리로 재생하고, 결과는 캐시한다.
/// 키가 없거나 합성 실패 시 기기 내장 flutter_tts(mn-MN)로 폴백한다.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  // --- 설정 (빌드 시 --dart-define 으로 주입) ---
  static const _azureKey = String.fromEnvironment('AZURE_SPEECH_KEY');
  static const _azureRegion =
      String.fromEnvironment('AZURE_SPEECH_REGION', defaultValue: 'koreacentral');
  static const _voice =
      String.fromEnvironment('AZURE_SPEECH_VOICE', defaultValue: 'mn-MN-YesuiNeural');

  /// 탭 후 재생까지의 지연(요청: 1초).
  static const _delay = Duration(seconds: 1);

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  final Map<String, String> _fileCache = {}; // text -> 로컬 mp3 경로
  Map<String, String>? _manifest; // clean text -> 번들 에셋 경로(audio/xxx.mp3)
  bool _ttsInited = false;
  bool available = true;
  int _seq = 0; // 빠른 연속 탭 시 직전 요청 취소용

  bool get _azureOn => _azureKey.isNotEmpty && !kIsWeb;

  Future<void> _initTts() async {
    if (_ttsInited) return;
    _ttsInited = true;
    try {
      final langs = (await _tts.getLanguages) as List?;
      available = langs == null ||
          langs.any((l) => l.toString().toLowerCase().startsWith('mn'));
      await _tts.setLanguage('mn-MN');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      available = false;
    }
  }

  /// 학습용 마크업·강세 기호 제거.
  String _clean(String text) => text
      .replaceAll(RegExp(r'\((?:원형)?[^)]*\)'), '')
      .replaceAll(RegExp(r'[\[\]{}]'), '')
      .replaceAll('__', '')
      .replaceAll('́', '')
      .trim();

  /// 1초 지연 후 재생. 연속 호출 시 마지막 것만 재생.
  Future<void> speak(String text) async {
    final clean = _clean(text);
    if (clean.isEmpty) return;

    await stop(); // 이전 재생/지연 취소 (_seq 증가)
    final my = ++_seq; // 그 다음 내 시퀀스 토큰을 잡는다
    await Future.delayed(_delay);
    if (my != _seq) return; // 그새 다른 문장이 들어옴 → 취소

    // 1) 사전 합성 음성 (Supabase Storage) — 다운로드 후 로컬 캐시 재생
    final url = (await _bundled())[clean];
    if (url != null) {
      try {
        final path = await _remoteFile(url);
        if (my != _seq) return;
        await _player.stop();
        await _player.play(DeviceFileSource(path));
        return;
      } catch (_) {
        // 실패(오프라인/DNS) → 런타임 Azure 폴백
      }
    }

    if (_azureOn) {
      try {
        final path = await _azureFile(clean);
        if (my != _seq) return;
        await _player.stop();
        await _player.play(DeviceFileSource(path));
        return;
      } catch (_) {
        // 실패 → 폴백
      }
    }
    await _initTts();
    if (my != _seq) return;
    await _tts.stop();
    await _tts.speak(clean);
  }

  Future<void> stop() async {
    _seq++; // 진행 중인 지연 취소
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  // --- 사전 합성 manifest (clean text -> Supabase 공개 mp3 URL) ---
  Future<Map<String, String>> _bundled() async {
    final m = _manifest;
    if (m != null) return m;
    try {
      final raw = await rootBundle.loadString('assets/audio/manifest.json');
      final map = (json.decode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as String));
      return _manifest = map;
    } catch (_) {
      return _manifest = <String, String>{};
    }
  }

  // 원격 mp3 다운로드 + 로컬 캐시 (재방문 시 즉시 재생)
  Future<String> _remoteFile(String url) async {
    final cached = _fileCache[url];
    if (cached != null && File(cached).existsSync()) return cached;

    final dir = await getTemporaryDirectory();
    final fname = '${dir.path}/sb_${url.hashCode}.mp3';
    final f = File(fname);
    if (await f.exists() && await f.length() > 1000) {
      _fileCache[url] = fname;
      return fname;
    }

    final client = HttpClient();
    try {
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw HttpException('audio ${resp.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in resp) {
        builder.add(chunk);
      }
      await f.writeAsBytes(builder.takeBytes(), flush: true);
      _fileCache[url] = fname;
      return fname;
    } finally {
      client.close();
    }
  }

  // --- Azure REST 합성 + 캐시 ---
  Future<String> _azureFile(String text) async {
    final cached = _fileCache[text];
    if (cached != null && File(cached).existsSync()) return cached;

    final dir = await getTemporaryDirectory();
    final fname = '${dir.path}/tts_${_voice}_${text.hashCode}.mp3';
    final f = File(fname);
    if (await f.exists() && await f.length() > 1000) {
      _fileCache[text] = fname;
      return fname;
    }

    final bytes = await _azureSynth(text);
    await f.writeAsBytes(bytes, flush: true);
    _fileCache[text] = fname;
    return fname;
  }

  Future<List<int>> _azureSynth(String text) async {
    final endpoint =
        'https://$_azureRegion.tts.speech.microsoft.com/cognitiveservices/v1';
    final ssml = '<speak version="1.0" xml:lang="mn-MN">'
        '<voice name="$_voice">${_xml(text)}</voice></speak>';
    final client = HttpClient();
    try {
      final req = await client.postUrl(Uri.parse(endpoint));
      req.headers.set('Ocp-Apim-Subscription-Key', _azureKey);
      req.headers.set('Content-Type', 'application/ssml+xml');
      req.headers
          .set('X-Microsoft-OutputFormat', 'audio-24khz-48kbitrate-mono-mp3');
      req.headers.set('User-Agent', 'mn-app-tts');
      req.add(utf8.encode(ssml));
      final resp = await req.close();
      if (resp.statusCode != 200) {
        throw HttpException('Azure TTS ${resp.statusCode}');
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in resp) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }

  String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
