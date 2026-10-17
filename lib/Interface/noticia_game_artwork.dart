import 'dart:async';

import 'package:flutter/material.dart';

import '../Class/WebScrap.dart';
import '../Modelos/NoticiaGame.dart';

/// Exibe a imagem retornada pelo feed e procura uma alternativa se ela faltar
/// ou se o servidor da notícia recusar o acesso direto.
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
  bool _searching = false;
  bool _searchAttempted = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = _httpImageUrl(widget.news.imgUrl);
    if (_imageUrl == null) {
      _searching = true;
      _searchAttempted = true;
      unawaited(_resolveAlternativeImage());
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

    _imageUrl = _httpImageUrl(widget.news.imgUrl);
    _searching = _imageUrl == null;
    _searchAttempted = _imageUrl == null;
    if (_searching) unawaited(_resolveAlternativeImage());
  }

  Future<void> _resolveAlternativeImage() async {
    String result = '';
    try {
      result = await WebScrap.buscaImagemAlternativaNoticia(
          widget.news.titulo, widget.news.veiculo);
    } catch (_) {}
    if (!mounted) return;

    final candidate = _httpImageUrl(result);
    setState(() {
      _searching = false;
      _imageUrl = candidate == _imageUrl ? null : candidate;
    });
  }

  void _searchAfterImageError() {
    if (_searchAttempted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _searchAttempted) return;
      setState(() {
        _searchAttempted = true;
        _searching = true;
      });
      unawaited(_resolveAlternativeImage());
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
              ? _placeholder()
              : Image.network(
                  _imageUrl!,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  headers: WebScrap.noticiaImageHeaders(widget.news.url),
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : _placeholder(loading: true),
                  errorBuilder: (_, __, ___) {
                    _searchAfterImageError();
                    return _placeholder(
                        loading: _searching || !_searchAttempted);
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
