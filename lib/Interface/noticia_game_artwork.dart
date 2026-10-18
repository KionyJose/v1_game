import 'dart:async';

import 'package:flutter/material.dart';

import '../Class/WebScrap.dart';
import '../Modelos/NoticiaGame.dart';

/// Exibe a imagem da notícia e tenta URLs alternativas quando uma fonte falha.
class NoticiaGameArtwork extends StatefulWidget {
  const NoticiaGameArtwork({
    super.key,
    required this.news,
    required this.accentColor,
    this.placeholderIconSize = 32,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final NoticiaGame news;
  final Color accentColor;
  final double placeholderIconSize;
  final BorderRadius borderRadius;

  @override
  State<NoticiaGameArtwork> createState() => _NoticiaGameArtworkState();
}

class _NoticiaGameArtworkState extends State<NoticiaGameArtwork> {
  String? _imageUrl;
  List<String> _fallbackImages = const [];
  int _fallbackIndex = -1;
  int _requestId = 0;
  bool _searching = false;
  bool _searchAttempted = false;
  bool _handlingImageError = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = _httpImageUrl(widget.news.imgUrl);
    if (_imageUrl == null) {
      _searching = true;
      _searchAttempted = true;
      unawaited(_resolveAlternativeImages(_requestId));
    }
  }

  @override
  void didUpdateWidget(covariant NoticiaGameArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.news.titulo == widget.news.titulo &&
        oldWidget.news.veiculo == widget.news.veiculo &&
        oldWidget.news.url == widget.news.url &&
        oldWidget.news.imgUrl == widget.news.imgUrl) {
      return;
    }

    _requestId++;
    _imageUrl = _httpImageUrl(widget.news.imgUrl);
    _fallbackImages = const [];
    _fallbackIndex = -1;
    _searching = _imageUrl == null;
    _searchAttempted = _imageUrl == null;
    _handlingImageError = false;
    if (_searching) unawaited(_resolveAlternativeImages(_requestId));
  }

  Future<void> _resolveAlternativeImages(int requestId) async {
    final news = widget.news;
    List<String> candidates = const [];
    try {
      candidates = await WebScrap.buscarCandidatasImagemNoticia(news);
    } catch (error) {
      debugPrint('Não foi possível localizar imagem da notícia: $error');
    }
    if (!mounted || requestId != _requestId) return;

    final currentImage = _httpImageUrl(news.imgUrl);
    final usable = candidates
        .map(_httpImageUrl)
        .whereType<String>()
        .where((candidate) => candidate != currentImage)
        .toSet()
        .toList();
    setState(() {
      _fallbackImages = usable;
      _fallbackIndex = usable.isEmpty ? -1 : 0;
      _imageUrl = usable.isEmpty ? null : usable.first;
      _searching = false;
    });
  }

  void _handleImageError(Object error) {
    if (_handlingImageError) return;
    _handlingImageError = true;
    final failedHost = Uri.tryParse(_imageUrl ?? '')?.host ?? 'URL inválida';
    debugPrint('Falha ao carregar imagem da notícia em $failedHost: $error');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handlingImageError = false;
      if (_searching) return;
      if (!_searchAttempted) {
        setState(() {
          _searchAttempted = true;
          _searching = true;
        });
        unawaited(_resolveAlternativeImages(_requestId));
        return;
      }

      final nextIndex = _fallbackIndex + 1;
      setState(() {
        _fallbackIndex = nextIndex < _fallbackImages.length ? nextIndex : -1;
        _imageUrl = _fallbackIndex < 0 ? null : _fallbackImages[_fallbackIndex];
      });
    });
  }

  String? _httpImageUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri.toString();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: widget.borderRadius,
        child: SizedBox.expand(
          child: _imageUrl == null
              ? _placeholder(loading: _searching)
              : Image.network(
                  _imageUrl!,
                  key: ValueKey(_imageUrl),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  headers: WebScrap.noticiaImageHeaders(widget.news.url),
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : _placeholder(loading: true),
                  errorBuilder: (_, error, __) {
                    _handleImageError(error);
                    return _placeholder(loading: _searching);
                  },
                ),
        ),
      );

  Widget _placeholder({bool loading = false}) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.accentColor.withValues(alpha: 0.3),
              const Color(0xFF101022),
            ],
          ),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: widget.placeholderIconSize * 0.65,
                  height: widget.placeholderIconSize * 0.65,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.accentColor,
                  ),
                )
              : Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white54,
                  size: widget.placeholderIconSize,
                ),
        ),
      );
}
