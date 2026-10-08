import 'dart:math';
import 'dart:isolate';
import '../Class/WebScrap.dart';
import '../Class/game_video_tags.dart';
import '../Modelos/NoticiaGame.dart';
import '../Modelos/videoYT.dart';

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
}

// HTTP parsing runs outside the UI isolate, including responses arriving during
// a route transition. Injected searches remain available for tests and callers.
Future<List<NoticiaGame>> _searchNews(String name) =>
    Isolate.run(() => WebScrap.buscaNoticiasGame(name));

Future<List<VideoYT>> _searchVideos(String name, String tag) =>
    Isolate.run(() => WebScrap.buscaVideosYT(name, tag));

/// News are cached; each completed video search advances the tag rotation.
class PersonalizedGameFeed {
  PersonalizedGameFeed(
      {this.newsSearch = _searchNews,
      this.videoSearch = _searchVideos,
      Random? random})
      : _random = random ?? Random();
  final Future<List<NoticiaGame>> Function(String) newsSearch;
  final Future<List<VideoYT>> Function(String, String) videoSearch;
  final Random _random;
  final _pending = <String, Future<FuturisticGameContent>>{};
  final _news = <String, ({DateTime time, Future<List<NoticiaGame>> value})>{};
  final _tags = <String, List<String>>{};
  final _previousTag = <String, String>{};
  final _seen = <String, Set<String>>{};

  void invalidate(String name) => _news.remove(name.trim().toLowerCase());

  Future<FuturisticGameContent> load(String name,
      {List<String> tags = GameVideoTags.values}) {
    final choices = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    if (choices.isEmpty) choices.addAll(GameVideoTags.values);
    final gameKey = name.trim().toLowerCase();
    final key = '$gameKey|${choices.join('|')}';
    if (_pending.containsKey(key)) return _pending[key]!;
    final request = _load(name, gameKey, key, choices);
    _pending[key] = request;
    request.then<void>((_) {
      _pending.remove(key);
    }, onError: (Object _, StackTrace __) {
      _pending.remove(key);
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
    if (_news.length >= 20) {
      final oldest = _news.keys.first;
      _news.remove(oldest);
      _seen.remove(oldest);
      _tags.removeWhere((key, _) => key.startsWith('$oldest|'));
      _previousTag.removeWhere((key, _) => key.startsWith('$oldest|'));
    }
    final result = newsSearch(name)
        .timeout(const Duration(seconds: 15), onTimeout: () => <NoticiaGame>[])
        .catchError((_) => <NoticiaGame>[]);
    _news[key] = (time: DateTime.now(), value: result);
    return result;
  }

  Future<FuturisticGameContent> _load(
      String name, String gameKey, String key, List<String> choices) async {
    final results = await Future.wait<Object>([
      _loadNews(name, gameKey),
      videoSearch(
              Uri.encodeQueryComponent('$name ${_nextTag(key, choices)}'), name)
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
}
