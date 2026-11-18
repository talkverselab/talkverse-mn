import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'learner_prefs.dart';
import 'script_sync.dart';
import '../core/embed_env.dart';
import '../core/prefs.dart';

/// 회화 리더(일본어앱 시안 02 「만화책 읽기형」)용 회화 모델 — 2026-11-02, 일본어앱 `dialogue_service.dart` 를 옮김.
///
/// 읽는 것(2026-11-18, 일본어앱 빌드 113·114 방식): 옛 `assets/data/dialogues/L1.json`(mn_d01·mn_d02) +
/// 편 파일 `assets/data/dialogues/R<급>/<주제>/<편id>.json`(150편). 편 파일은 [ScriptSync.load] 로 읽어
/// 서버에 더 새 원고가 있으면 그것을 쓴다(일본어앱 `docs/CONTENT_SYNC.md` §6). 편 id·턴 번호는 다시 매기지 않는다.
/// 칸: tl = 몽골어(키릴; 편 파일은 `tl`, 옛 L1 은 템플릿 이름 `es`), gloss = 없음, rd = 한글 독음, ko = 한국어.
class DialogueTurn {
  final int num;
  final String speaker; // A·B
  final String tl;
  final String gloss;
  final String rd;
  final String ko;
  final String note;
  final List<String> tags;
  final String? art; // 장면 그림 URL(나중에 채움)
  /// 「어순 맞대기」 낱말 대응 [(몽골어, 한국어)] — 데이터에 `align: [[mn, ko], …]` 가 있을 때만(회화 작업 때 채움).
  final List<(String, String)> align;
  /// 문장 내용어 `lemmas: [[표면형, 기본형, 읽기]]`(있을 때만 — 없으면 앱이 접사 분석으로 만든다, 2026-11-04).
  final List<(String, String, String)> lemmas;
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.tl,
    required this.gloss,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    this.art,
    this.align = const [],
    this.lemmas = const [],
  });

  factory DialogueTurn.fromL1(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: (j['tl'] ?? j['es']) as String? ?? '',
        gloss: j['gloss'] as String? ?? '',
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
        align: [
          for (final a in (j['align'] as List? ?? const []))
            if (a is List && a.length >= 2) ('${a[0]}', '${a[1]}'),
        ],
        lemmas: [
          for (final l in (j['lemmas'] as List? ?? const []))
            if (l is List && l.length >= 2) ('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : ''),
        ],
      );

  /// 그림 조회용 핵심 단어 후보: 몽골어 문장의 낱말(소문자, 2자 이상).
  List<String> get pictureWords => [
        for (final w in tl.toLowerCase().split(RegExp(r'[^\p{L}\p{M}]+', unicode: true)))
          if (w.length >= 2) w,
      ];
}

class Dialogue {
  final String id;
  final String region; // R1·R2·R3(편 파일) · L1(옛 이야기 2편)
  final String island; // 주제
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers;
  final Map<String, String> genders;
  final List<String> expressions;
  final List<DialogueTurn> turns;
  final String? art;
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    required this.expressions,
    required this.turns,
    this.art,
  });

  /// 화자 표시 이름. `{name}` 자리는 학습자 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 목소리 성별 — 옛 L1 은 화자 성별이 데이터에 정해져 있다(A 민 남 · B 사라 여). 편 파일은 학습자 설정을 따른다.
  String voiceGender(String sp) => genders[sp] ?? LearnerPrefs.voiceGender(sp);

  /// 편 파일(`R*/<주제>/<id>.json`) 하나 → 회화.
  factory Dialogue.fromJson(Map<String, dynamic> j) => Dialogue(
        id: j['id'] as String,
        region: j['region'] as String? ?? 'R1',
        island: j['island'] as String? ?? '',
        title: j['title'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '💬',
        scene: j['scene'] as String? ?? '',
        speakers: ((j['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
        genders: ((j['genders'] as Map?) ?? const {}).map((k, v) => MapEntry(k.toString(), v.toString())),
        expressions: (j['expressions'] as List?)?.map((e) => '$e').toList() ?? const [],
        turns: ((j['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList(),
        art: j['art'] as String?,
      );

  /// 편 순서 키: survival(s) → a → b → c, 번호 순(일본어앱과 같음). 옛 L1 은 id 그대로.
  String get orderKey {
    final m = RegExp(r'_([abcs])(\d+)$').firstMatch(id);
    if (m == null) return id;
    const o = {'s': 0, 'a': 1, 'b': 2, 'c': 3};
    return '${o[m.group(1)]}${m.group(2)!.padLeft(2, '0')}';
  }
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '일',
    'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🆘',
    'friends': '🤝',
    'love': '💘',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '🎓',
  };
  static const levelKo = {'L1': '이야기', 'R0': '왕초보', 'R1': '초보', 'R2': '중급', 'R3': '고급', 'R4': '최상급'};
  /// 화면에 보이는 급 순서(편이 있는 급만 [regions] 에 나온다).
  static const levels = ['R0', 'R1', 'R2', 'R3', 'R4', 'L1'];
  static const _prefLast = 'dialogue_last';

  final List<Dialogue> _all = [];
  Future<void>? _loading;
  String? _lastOpened;
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await Prefs.getInstance()).setString(_prefLast, id);
  }

  /// 넓은 화면에서 탭이 동시에 떠 두 번 불려도 한 번만 읽는다(플래그로 막으면 경쟁으로 목록이 두 번 찬다).
  Future<void> ensureLoaded() => _loading ??= _load();

  /// 원고가 서버 판으로 바뀌어 다시 읽힐 때마다 오른다.
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<void> _load() async {
    _lastOpened = (await Prefs.getInstance()).getString(_prefLast);
    await _readAll();
    // 서버에 더 새 원고가 있으면 뒤에서 받아 다시 읽는다(없거나 실패하면 그대로)
    ScriptSync.instance.refresh().then((changed) async {
      if (!changed) return;
      await _readAll();
      revision.value++;
    });
  }

  /// 옛 L1 + 앱 안 편 파일 + 서버에서 받은 새 편 − 서버 판에서 빠진 편. 각 파일은 덮어쓴 판이 있으면 그것([ScriptSync]).
  Future<void> _readAll() async {
    final next = <Dialogue>[];
    final sync = ScriptSync.instance;
    await sync.init();
    try {
      final j = json.decode(await sync.load('dialogues/L1.json')) as Map<String, dynamic>;
      final chars = (j['characters'] as Map<String, dynamic>? ?? const {});
      final names = chars.map((k, v) => MapEntry(k, ((v as Map)['name'] ?? k).toString()));
      final genders = chars.map((k, v) => MapEntry(k, ((v as Map)['gender'] ?? 'female').toString()));
      final level = j['level'] as String? ?? 'L1';
      for (final e in (j['episodes'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        final turns = ((m['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList();
        if (turns.isEmpty) continue;
        next.add(Dialogue(
          id: '${level}_${m['id']}',
          region: level,
          island: 'love', // 옛 L1 = 게스트하우스에서 만나 초원 데이트로 가는 연애 이야기(원칙: 기존 연애 서사는 love 주제)
          title: m['title'] as String? ?? m['id'] as String,
          emoji: m['emoji'] as String? ?? '💬',
          scene: m['scenario'] as String? ?? '',
          speakers: names,
          genders: genders,
          expressions: const [],
          turns: turns,
        ));
      }
    } catch (_) {}
    final rels = <String>{};
    final pat = RegExp(r'^assets/data/dialogues/R[0-4]/[^/]+/[^/]+\.json$');
    try {
      // 매니페스트 키는 통합 앱이면 packages/mn_app/ 가 붙어 있다 — 접두를 떼고 견준다
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      rels.addAll([for (final p in manifest.listAssets().map(stripAssetPrefix).where(pat.hasMatch)) p.substring('assets/data/'.length)]);
    } catch (_) {}
    rels
      ..addAll(sync.added.where((p) => pat.hasMatch('assets/data/$p')))
      ..removeAll(sync.removed);
    final eps = <Dialogue>[];
    for (final rel in rels) {
      try {
        final d = Dialogue.fromJson(json.decode(await sync.load(rel)) as Map<String, dynamic>);
        if (d.turns.isNotEmpty) eps.add(d);
      } catch (_) {}
    }
    int lv(String r) => levels.contains(r) ? levels.indexOf(r) : levels.length;
    eps.sort((a, b) {
      final c = lv(a.region).compareTo(lv(b.region));
      if (c != 0) return c;
      final i = islands.indexOf(a.island).compareTo(islands.indexOf(b.island));
      return i != 0 ? i : a.orderKey.compareTo(b.orderKey);
    });
    // 편 파일 먼저(급 순서), 옛 L1 은 뒤에 — 「오늘의 컷」 기본 편이 초보 편이 되게
    _all
      ..clear()
      ..addAll(eps)
      ..addAll(next.where((d) => !eps.any((e) => e.id == d.id)));
  }

  Dialogue? byId(String id) => _all.where((d) => d.id == id).firstOrNull;
  List<Dialogue> get all => List.unmodifiable(_all);
  List<String> get regions {
    final has = _all.map((d) => d.region).toSet();
    return [...levels.where(has.contains), ...has.where((r) => !levels.contains(r))];
  }

  List<Dialogue> list({String? region, String? island}) =>
      _all.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();

  List<String> islandsOf(String region) {
    final has = _all.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _all.where((d) => d.region == region).length;
}
