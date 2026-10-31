import 'dart:convert';

import 'package:guptik/models/mediaplyer/player_video_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One watched video, stored on the phone only.
class LocalHistoryRecord {
  final String videoId;
  final String title;
  final List<String> tags;
  final String channelName;
  final String category;
  final String creatorUrl;
  final String? thumbnailUrl;
  final bool isReel;

  /// When it was last watched (UTC, ISO-8601).
  final DateTime watchedAt;

  /// When it was first watched (UTC, ISO-8601).
  final DateTime firstWatchedAt;
  final int watchCount;
  final int positionSeconds;
  final int durationSeconds;

  /// Full video payload so it can be replayed straight from history.
  final Map<String, dynamic> video;

  const LocalHistoryRecord({
    required this.videoId,
    required this.title,
    required this.tags,
    required this.channelName,
    required this.category,
    required this.creatorUrl,
    required this.thumbnailUrl,
    required this.isReel,
    required this.watchedAt,
    required this.firstWatchedAt,
    required this.watchCount,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.video,
  });

  double get progress =>
      durationSeconds > 0 ? (positionSeconds / durationSeconds).clamp(0.0, 1.0) : 0.0;

  PlayerVideo toPlayerVideo() => PlayerVideo.fromJson(video, creatorUrl);

  LocalHistoryRecord copyWith({
    DateTime? watchedAt,
    int? watchCount,
    int? positionSeconds,
    int? durationSeconds,
    Map<String, dynamic>? video,
    String? title,
    List<String>? tags,
  }) =>
      LocalHistoryRecord(
        videoId: videoId,
        title: title ?? this.title,
        tags: tags ?? this.tags,
        channelName: channelName,
        category: category,
        creatorUrl: creatorUrl,
        thumbnailUrl: thumbnailUrl,
        isReel: isReel,
        watchedAt: watchedAt ?? this.watchedAt,
        firstWatchedAt: firstWatchedAt,
        watchCount: watchCount ?? this.watchCount,
        positionSeconds: positionSeconds ?? this.positionSeconds,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        video: video ?? this.video,
      );

  Map<String, dynamic> toJson() => {
        'video_id': videoId,
        'title': title,
        'tags': tags,
        'channel_name': channelName,
        'category': category,
        'creator_url': creatorUrl,
        'thumbnail_url': thumbnailUrl,
        'is_reel': isReel,
        'watched_at': watchedAt.toIso8601String(),
        'first_watched_at': firstWatchedAt.toIso8601String(),
        'watch_count': watchCount,
        'position_seconds': positionSeconds,
        'duration_seconds': durationSeconds,
        'video': video,
      };

  factory LocalHistoryRecord.fromJson(Map<String, dynamic> j) {
    final watched = DateTime.tryParse(j['watched_at']?.toString() ?? '') ?? DateTime.now().toUtc();
    return LocalHistoryRecord(
      videoId: j['video_id']?.toString() ?? '',
      title: j['title']?.toString() ?? 'Untitled',
      tags: (j['tags'] is List) ? (j['tags'] as List).map((e) => e.toString()).toList() : const [],
      channelName: j['channel_name']?.toString() ?? '',
      category: j['category']?.toString() ?? '',
      creatorUrl: j['creator_url']?.toString() ?? '',
      thumbnailUrl: j['thumbnail_url']?.toString(),
      isReel: j['is_reel'] == true,
      watchedAt: watched,
      firstWatchedAt: DateTime.tryParse(j['first_watched_at']?.toString() ?? '') ?? watched,
      watchCount: (j['watch_count'] as num?)?.toInt() ?? 1,
      positionSeconds: (j['position_seconds'] as num?)?.toInt() ?? 0,
      durationSeconds: (j['duration_seconds'] as num?)?.toInt() ?? 0,
      video: (j['video'] is Map) ? Map<String, dynamic>.from(j['video']) : <String, dynamic>{},
    );
  }
}

/// Phone-local watch history for the GupTik media player.
///
/// Keeps at most [maxRecords] entries (newest first). Re-watching a video moves
/// it to the top instead of adding a duplicate. Works with no login and no node
/// connection, so it also covers incognito / unpaired viewers.
class LocalMediaHistoryService {
  LocalMediaHistoryService._();
  static final LocalMediaHistoryService instance = LocalMediaHistoryService._();

  static const int maxRecords = 500;
  static const String _key = 'guptik_local_media_history_v1';
  static const String _pausedKey = 'guptik_local_media_history_paused';

  List<LocalHistoryRecord>? _cache;

  Future<List<LocalHistoryRecord>> _load() async {
    if (_cache != null) return _cache!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return _cache = [];
    try {
      final list = jsonDecode(raw) as List;
      _cache = list
          .whereType<Map>()
          .map((m) => LocalHistoryRecord.fromJson(Map<String, dynamic>.from(m)))
          .where((r) => r.videoId.isNotEmpty)
          .toList();
    } catch (_) {
      _cache = [];
    }
    return _cache!;
  }

  Future<void> _save(List<LocalHistoryRecord> records) async {
    if (records.length > maxRecords) {
      records.removeRange(maxRecords, records.length);
    }
    _cache = records;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  /// Whether the user turned history recording off.
  Future<bool> isPaused() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pausedKey) ?? false;
  }

  Future<void> setPaused(bool paused) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pausedKey, paused);
  }

  /// Call when playback starts. Adds or bumps the record to the top.
  Future<void> recordWatch(PlayerVideo video) async {
    if (video.videoId.isEmpty || await isPaused()) return;
    final records = List<LocalHistoryRecord>.from(await _load());
    final now = DateTime.now().toUtc();
    final idx = records.indexWhere((r) => r.videoId == video.videoId);
    if (idx >= 0) {
      final old = records.removeAt(idx);
      records.insert(
        0,
        old.copyWith(
          watchedAt: now,
          watchCount: old.watchCount + 1,
          video: video.toJson(),
          title: video.title,
          tags: video.tags,
        ),
      );
    } else {
      records.insert(
        0,
        LocalHistoryRecord(
          videoId: video.videoId,
          title: video.title,
          tags: List<String>.from(video.tags),
          channelName: video.channelName,
          category: video.category,
          creatorUrl: video.creatorUrl,
          thumbnailUrl: video.thumbnailUrl,
          isReel: video.isReel,
          watchedAt: now,
          firstWatchedAt: now,
          watchCount: 1,
          positionSeconds: 0,
          durationSeconds: 0,
          video: video.toJson(),
        ),
      );
    }
    await _save(records);
  }

  /// Call when playback stops, to remember how far they got.
  Future<void> updateProgress(String videoId, int positionSeconds, int durationSeconds) async {
    if (videoId.isEmpty) return;
    final records = List<LocalHistoryRecord>.from(await _load());
    final idx = records.indexWhere((r) => r.videoId == videoId);
    if (idx < 0) return;
    records[idx] = records[idx].copyWith(
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
    );
    await _save(records);
  }

  /// Newest first. Optional text query matches title, channel, category and tags;
  /// [tag] filters to an exact tag; [from]/[to] bound the last-watched date.
  Future<List<LocalHistoryRecord>> getAll({
    String? query,
    String? tag,
    DateTime? from,
    DateTime? to,
    bool? reelsOnly,
  }) async {
    final q = query?.trim().toLowerCase() ?? '';
    final t = tag?.trim().toLowerCase();
    return (await _load()).where((r) {
      if (reelsOnly != null && r.isReel != reelsOnly) return false;
      if (from != null && r.watchedAt.isBefore(from.toUtc())) return false;
      if (to != null && r.watchedAt.isAfter(to.toUtc())) return false;
      if (t != null && t.isNotEmpty && !r.tags.any((x) => x.toLowerCase() == t)) return false;
      if (q.isEmpty) return true;
      return r.title.toLowerCase().contains(q) ||
          r.channelName.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q) ||
          r.tags.any((x) => x.toLowerCase().contains(q));
    }).toList();
  }

  /// Most-watched tags, useful for "because you watched" chips.
  Future<List<MapEntry<String, int>>> topTags({int limit = 10}) async {
    final counts = <String, int>{};
    for (final r in await _load()) {
      for (final tag in r.tags) {
        counts[tag] = (counts[tag] ?? 0) + r.watchCount;
      }
    }
    final list = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).toList();
  }

  Future<int> count() async => (await _load()).length;

  Future<void> remove(String videoId) async {
    final records = List<LocalHistoryRecord>.from(await _load())
      ..removeWhere((r) => r.videoId == videoId);
    await _save(records);
  }

  Future<void> clear() async => _save([]);
}
