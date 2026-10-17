import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show debugPrint;

import '../Class/WebScrap.dart';
import '../Class/game_video_tags.dart';
import '../Modelos/NoticiaGame.dart';
import '../Modelos/videoYT.dart';
import '../System/app_storage.dart';

class FuturisticGameContent {
  const FuturisticGameContent({this.news = const [], this.videos = const []});
  final List<NoticiaGame> news;
  final List<VideoYT> videos;
}

class FuturisticGameFeed {
  static final _loader = PersonalizedGameFeed();

  static Future<FuturisticGameContent> load(String name,
          {List<String> tags = GameVideoTags.values}) =>
      _loader.load(name, tags: tags);

  static void invalidate(String name) => _loader.invalidate(name);

  /// Sincroniza o cache com a biblioteca e prepara os feeds sem bloquear a UI.
  static Future<void> prepareLibrary(Iterable<String> names,
          {String? priorityName}) =>
      _loader.prepareLibrary(names, priorityName: priorityName);
}

// HTTP parsing runs outside the UI isolate, including responses arriving during
// a route transition. Injected searches remain available for callers.
Future<List<NoticiaGame>> _searchNews(String name) =>
    Isolate.run(() => WebScrap.buscaNoticiasGame(name));

Future<List<VideoYT>> _searchVideos(String name, String tag) =>
    Isolate.run(() => WebScrap.buscaVideosYT(name, tag));

/// Keeps each installed game's latest feed on disk and warms the rest in the
/// background. A stale snapshot is still returned immediately while refreshing.
class PersonalizedGameFeed {
  PersonalizedGameFeed(
      {this.newsSearch = _searchNews,
      this.videoSearch = _searchVideos,
      Random? random})
      : _random = random ?? Random();

  static const _cacheFileName = 'futuristic_game_feed_cache.json';
  static const _cacheVersion = 1;
  static const _cacheLifetime = Duration(hours: 12);
  static const _prefetchConcurrency = 2;

  final Future<List<NoticiaGame>> Function(String) newsSearch;
  final Future<List<VideoYT>> Function(String, String) videoSearch;
  final Random _random;
  final _pending = <String, Future<FuturisticGameContent>>{};
  final _news = <String, ({DateTime time, Future<List<NoticiaGame>> value})>{};
  final _tags = <String, List<String>>{};
  final _previousTag = <String, String>{};
  final _seen = <String, Set<String>>{};
  final _content = <String, _CachedFeed>{};
  final _libraryKeys = <String>{};

  Future<void>? _cacheRead;
  Future<void> _cacheWrite = Future.value();
  Timer? _cacheWriteTimer;
  Future<void>? _preloadTask;
  String? _preloadFingerprint;
  bool _preloadInProgress = false;
  int _libraryEpoch = 0;

  Future<void> _ensureCacheLoaded() => _cacheRead ??= _readCache();

  Future<void> _readCache() async {
    try {
      final file = AppStorage.dataFile(_cacheFileName);
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      final root = _asStringMap(decoded);
      if (root == null || root['version'] != _cacheVersion) return;
      final games = _asStringMap(root['games']);
      if (games == null) return;

      for (final entry in games.entries) {
        final value = _asStringMap(entry.value);
        if (value == null) continue;
        final savedAt = DateTime.tryParse(_asString(value['savedAt']));
        final news = _decodeNews(value['news']);
        final videos = _decodeVideos(value['videos']);
        if (savedAt == null) continue;
        _content[entry.key] = _CachedFeed(
            savedAt: savedAt,
            content: FuturisticGameContent(news: news, videos: videos));
      }
    } catch (error) {
      // A damaged or older cache must never prevent the live search from working.
      debugPrint('Não foi possível ler o cache de jogos futurista: $error');
    }
  }

  Future<void> prepareLibrary(Iterable<String> names,
      {String? priorityName}) async {
    await _ensureCacheLoaded();

    final gamesByKey = <String, String>{};
    for (final name in names) {
      final cleanName = name.trim();
      final key = _gameKey(cleanName);
      if (key.isNotEmpty) gamesByKey.putIfAbsent(key, () => cleanName);
    }
    final activeKeys = gamesByKey.keys.toSet();
    final fingerprint = (activeKeys.toList()..sort()).join('\u0000');
    final libraryChanged = fingerprint != _preloadFingerprint;

    if (libraryChanged) {
      _libraryEpoch++;
      _preloadFingerprint = fingerprint;
      _libraryKeys
        ..clear()
        ..addAll(activeKeys);
      _content.removeWhere((key, _) => !activeKeys.contains(key));
      _news.removeWhere((key, _) => !activeKeys.contains(key));
      _seen.removeWhere((key, _) => !activeKeys.contains(key));
      _tags.removeWhere((key, _) => !activeKeys.contains(key.split('|').first));
      _previousTag
          .removeWhere((key, _) => !activeKeys.contains(key.split('|').first));
      _scheduleCacheWrite();
    }

    if (_preloadInProgress && !libraryChanged && _preloadTask != null) {
      await _preloadTask;
      return;
    }

    final orderedGames = gamesByKey.entries.toList();
    final priorityKey = _gameKey(priorityName ?? '');
    orderedGames.sort((a, b) {
      if (a.key == priorityKey) return -1;
      if (b.key == priorityKey) return 1;
      return 0;
    });
    final toLoad = orderedGames
        .where((entry) => _needsRefresh(_content[entry.key]))
        .toList();
    if (toLoad.isEmpty) return;

    final epoch = _libraryEpoch;
    _preloadInProgress = true;
    final task = _preloadGames(toLoad, epoch);
    _preloadTask = task;
    try {
      await task;
    } finally {
      if (epoch == _libraryEpoch) _preloadInProgress = false;
    }
  }

  Future<void> _preloadGames(
      List<MapEntry<String, String>> games, int epoch) async {
    for (var start = 0; start < games.length; start += _prefetchConcurrency) {
      if (epoch != _libraryEpoch) return;
      final batch = games.skip(start).take(_prefetchConcurrency);
      await Future.wait(batch.map((entry) => _requestFresh(
                  entry.value, entry.key, GameVideoTags.values,
                  libraryEpoch: epoch)
              .then<void>((content) {
            if (epoch == _libraryEpoch &&
                _libraryKeys.contains(entry.key) &&
                !_content.containsKey(entry.key)) {
              _content[entry.key] =
                  _CachedFeed(savedAt: DateTime.now(), content: content);
              _scheduleCacheWrite();
            }
          }, onError: (Object _) {})));
    }
  }

  void invalidate(String name) {
    final key = _gameKey(name);
    _news.remove(key);
    _content.remove(key);
    _seen.remove(key);
    _tags.removeWhere((entryKey, _) => entryKey.startsWith('$key|'));
    _previousTag.removeWhere((entryKey, _) => entryKey.startsWith('$key|'));
    _scheduleCacheWrite();
  }

  Future<FuturisticGameContent> load(String name,
      {List<String> tags = GameVideoTags.values}) async {
    await _ensureCacheLoaded();
    final choices = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    if (choices.isEmpty) choices.addAll(GameVideoTags.values);
    final gameKey = _gameKey(name);
    final cached = _content[gameKey];
    if (cached != null) {
      if (_needsRefresh(cached)) {
        unawaited(_requestFresh(name, gameKey, choices)
            .then<void>((_) {}, onError: (Object _) {}));
      }
      return cached.content;
    }
    return _requestFresh(name, gameKey, choices);
  }

  bool _needsRefresh(_CachedFeed? feed) =>
      feed == null ||
      DateTime.now().difference(feed.savedAt) >= _cacheLifetime ||
      feed.content.news.any((news) =>
          news.imgUrl.isNotEmpty && !_isHttpImageUrl(news.imgUrl));

  bool _isHttpImageUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Future<FuturisticGameContent> _requestFresh(
      String name, String gameKey, List<String> choices,
      {int? libraryEpoch}) {
    final existing = _pending[gameKey];
    if (existing != null) return existing;
    final epochAtStart = libraryEpoch ?? _libraryEpoch;
    final request = _load(name, gameKey, choices).then((content) {
      final belongsToCurrentLibrary =
          _libraryKeys.isEmpty || _libraryKeys.contains(gameKey);
      if (epochAtStart == _libraryEpoch && belongsToCurrentLibrary) {
        _content[gameKey] =
            _CachedFeed(savedAt: DateTime.now(), content: content);
        _scheduleCacheWrite();
      }
      return content;
    });
    _pending[gameKey] = request;
    request.then<void>((_) {
      if (identical(_pending[gameKey], request)) _pending.remove(gameKey);
    }, onError: (Object _, StackTrace __) {
      if (identical(_pending[gameKey], request)) _pending.remove(gameKey);
    });
    return request;
  }

  String _nextTag(String key, List<String> choices) {
    var bag = _tags[key];
    if (bag == null || bag.isEmpty) {
      bag = List.of(choices)..shuffle(_random);
      if (bag.length > 1 && bag.last == _previousTag[key]) {
        final first = bag.first;
        bag[0] = bag.last;
        bag[bag.length - 1] = first;
      }
      _tags[key] = bag;
    }
    final tag = bag.removeLast();
    _previousTag[key] = tag;
    return tag;
  }

  Future<List<NoticiaGame>> _loadNews(String name, String key) {
    final cached = _news[key];
    if (cached != null &&
        DateTime.now().difference(cached.time).inMinutes < 5) {
      return cached.value;
    }
    final result = newsSearch(name)
        .timeout(const Duration(seconds: 15), onTimeout: () => <NoticiaGame>[])
        .catchError((_) => <NoticiaGame>[]);
    _news[key] = (time: DateTime.now(), value: result);
    return result;
  }

  Future<FuturisticGameContent> _load(
      String name, String gameKey, List<String> choices) async {
    final tagKey = '$gameKey|${choices.join('|')}';
    final results = await Future.wait<Object>([
      _loadNews(name, gameKey),
      videoSearch(
              Uri.encodeQueryComponent('$name ${_nextTag(tagKey, choices)}'),
              name)
          .timeout(const Duration(seconds: 15), onTimeout: () => <VideoYT>[])
          .catchError((_) => <VideoYT>[]),
    ]);
    final unique = <String, VideoYT>{};
    for (final video in results[1] as List<VideoYT>) {
      unique.putIfAbsent(video.videoID, () => video);
    }
    final candidates = unique.values.toList()..shuffle(_random);
    final seen = _seen.putIfAbsent(gameKey, () => <String>{});
    var fresh = candidates
        .where((video) => !seen.contains(video.videoID))
        .take(10)
        .toList();
    if (fresh.isEmpty) fresh = candidates.take(10).toList();
    if (seen.length > 200) seen.clear();
    seen.addAll(fresh.map((video) => video.videoID));
    return FuturisticGameContent(
        news: (results[0] as List<NoticiaGame>).take(8).toList(),
        videos: fresh);
  }

  Future<void> _writeCache() {
    final snapshot = <String, dynamic>{
      'version': _cacheVersion,
      'games': {
        for (final entry in _content.entries)
          entry.key: {
            'savedAt': entry.value.savedAt.toIso8601String(),
            'news': entry.value.content.news.map(_newsToMap).toList(),
            'videos': entry.value.content.videos.map(_videoToMap).toList(),
          },
      },
    };
    final encoded = jsonEncode(snapshot);
    _cacheWrite = _cacheWrite.then((_) async {
      try {
        final file = AppStorage.dataFile(_cacheFileName);
        await file.parent.create(recursive: true);
        await file.writeAsString(encoded, flush: true);
      } catch (error) {
        debugPrint(
            'Não foi possível salvar o cache de jogos futurista: $error');
      }
    });
    return _cacheWrite;
  }

  void _scheduleCacheWrite() {
    _cacheWriteTimer?.cancel();
    _cacheWriteTimer = Timer(const Duration(milliseconds: 250), () {
      _cacheWriteTimer = null;
      unawaited(_writeCache());
    });
  }

  Map<String, dynamic> _newsToMap(NoticiaGame news) => {
        'titulo': news.titulo,
        'veiculo': news.veiculo,
        'descricao': news.descricao,
        'url': news.url,
        'dataStr': news.dataStr,
        'imgUrl': news.imgUrl,
      };

  Map<String, dynamic> _videoToMap(VideoYT video) => {
        'titulo': video.titulo,
        'urlVideo': video.urlVideo,
        'capaP': video.capaP,
        'capaM': video.capaM,
        'capaG': video.capaG,
        'descricao': video.descricao,
        'canal': video.canal,
        'data': video.data,
        'videoID': video.videoID,
        'nomeGame': video.nomeGame,
      };

  List<NoticiaGame> _decodeNews(Object? value) {
    if (value is! List) return [];
    return value
        .map((item) {
          final map = _asStringMap(item);
          if (map == null) return null;
          return NoticiaGame(
            titulo: _asString(map['titulo']),
            veiculo: _asString(map['veiculo']),
            descricao: _asString(map['descricao']),
            url: _asString(map['url']),
            dataStr: _asString(map['dataStr']),
            imgUrl: _asString(map['imgUrl']),
          );
        })
        .whereType<NoticiaGame>()
        .toList();
  }

  List<VideoYT> _decodeVideos(Object? value) {
    if (value is! List) return [];
    return value
        .map((item) {
          final map = _asStringMap(item);
          if (map == null) return null;
          final video = VideoYT()
            ..titulo = _asString(map['titulo'])
            ..urlVideo = _asString(map['urlVideo'])
            ..capaP = _asString(map['capaP'])
            ..capaM = _asString(map['capaM'])
            ..capaG = _asString(map['capaG'])
            ..descricao = _asString(map['descricao'])
            ..canal = _asString(map['canal'])
            ..data = _asString(map['data'])
            ..videoID = _asString(map['videoID'])
            ..nomeGame = _asString(map['nomeGame']);
          return video;
        })
        .whereType<VideoYT>()
        .toList();
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  String _asString(Object? value) => value is String ? value : '';

  String _gameKey(String name) => name.trim().toLowerCase();
}

class _CachedFeed {
  const _CachedFeed({required this.savedAt, required this.content});
  final DateTime savedAt;
  final FuturisticGameContent content;
}
