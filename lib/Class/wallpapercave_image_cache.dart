import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

class WallpapercaveImageCache {
  static const Map<String, String> headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            'Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    'Referer': 'https://wallpapercave.com/',
  };

  static final _RateLimitedImageFileService _fileService =
      _RateLimitedImageFileService();

  static final CacheManager manager = CacheManager(
    Config(
      'wallpapercave-image-cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 400,
      fileService: _fileService,
    ),
  );

  static Future<http.Response> get(Uri uri) => _fileService.getResponse(uri);
}

class _RateLimitedImageFileService extends FileService {
  _RateLimitedImageFileService() {
    // Wallpapercave starts returning 429 when several images arrive together.
    concurrentFetches = 1;
  }

  final http.Client _client = http.Client();
  Future<void> _requestQueue = Future<void>.value();
  DateTime? _lastRequestAt;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async =>
      HttpGetResponse(await _fetch(url, headers: headers));

  Future<http.Response> getResponse(Uri uri) async {
    return http.Response.fromStream(await _fetch(
      uri.toString(),
      headers: WallpapercaveImageCache.headers,
    ));
  }

  Future<http.StreamedResponse> _fetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    final completer = Completer<http.StreamedResponse>();
    _requestQueue = _requestQueue.then((_) async {
      try {
        completer.complete(await _fetchQueued(url, headers: headers));
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<http.StreamedResponse> _fetchQueued(
    String url, {
    Map<String, String>? headers,
  }) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      await _waitBetweenRequests();
      final request = http.Request('GET', Uri.parse(url))
        ..headers.addAll(WallpapercaveImageCache.headers)
        ..headers.addAll(headers ?? const <String, String>{});
      final streamedResponse =
          await _client.send(request).timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse)
          .timeout(const Duration(seconds: 45));

      if (response.statusCode != HttpStatus.tooManyRequests || attempt == 3) {
        return http.StreamedResponse(
          Stream<List<int>>.value(response.bodyBytes),
          response.statusCode,
          contentLength: response.bodyBytes.length,
          request: response.request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      }

      final retryDelay = _retryDelay(response.headers['retry-after'], attempt);
      await Future<void>.delayed(retryDelay);
    }

    throw StateError('A tentativa de carregar a imagem terminou sem resposta.');
  }

  Future<void> _waitBetweenRequests() async {
    final lastRequestAt = _lastRequestAt;
    if (lastRequestAt != null) {
      const minimumGap = Duration(milliseconds: 700);
      final elapsed = DateTime.now().difference(lastRequestAt);
      final remaining = minimumGap - elapsed;
      if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    }
    _lastRequestAt = DateTime.now();
  }

  Duration _retryDelay(String? retryAfter, int attempt) {
    final value = retryAfter?.trim();
    if (value != null && value.isNotEmpty) {
      final seconds = int.tryParse(value);
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds.clamp(1, 120).toInt());
      }
      try {
        final retryAt = HttpDate.parse(value).toUtc();
        final remaining = retryAt.difference(DateTime.now().toUtc());
        if (remaining > Duration.zero) {
          return remaining > const Duration(minutes: 2)
              ? const Duration(minutes: 2)
              : remaining;
        }
      } on FormatException {
        // Use the increasing fallback delay for an invalid Retry-After value.
      }
    }

    return Duration(seconds: 2 << attempt);
  }
}
