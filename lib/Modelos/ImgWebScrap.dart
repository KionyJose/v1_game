// ignore_for_file: file_names

class ImgWebScrap {
  String title;
  String imageUrl;
  String tipo;
  String altura;
  String largura;
  String folderUrl;

  /// Quantas imagens a pasta guarda. Zero quando o resultado é uma imagem
  /// solta, e não um álbum.
  int fotos;

  ImgWebScrap({
    this.altura = "",
    this.largura = "",
    this.title = "",
    this.imageUrl = "",
    this.tipo = "",
    this.folderUrl = "",
    this.fotos = 0,
  });

  fromMapImgFinal(Map<String, String> map,
      {String baseUrl = 'https://wallpapercave.com/'}) {
    title = map['alt'] ?? "";
    imageUrl = '';
    for (final candidate in [
      map['data-src'],
      map['data-lazy-src'],
      map['data-original'],
      _largestSrcSetImage(map['data-srcset'] ?? map['srcset'] ?? ''),
      map['src'],
    ]) {
      if (candidate == null || candidate.trim().isEmpty) continue;
      imageUrl = _resolveImageUrl(candidate, baseUrl);
      if (imageUrl.isNotEmpty) break;
    }
    tipo = map['class'] ?? "";
    altura = map['height'] ?? "";
    largura = map['width'] ?? "";
  }

  static String _largestSrcSetImage(String srcSet) {
    if (srcSet.trim().isEmpty) return '';
    final candidates = srcSet
        .split(',')
        .map((candidate) {
          final parts = candidate.trim().split(RegExp(r'\s+'));
          return parts.isEmpty ? '' : parts.first;
        })
        .where((url) => url.isNotEmpty)
        .toList();
    return candidates.isEmpty ? '' : candidates.last;
  }

  static String _resolveImageUrl(String raw, String baseUrl) {
    final value = raw.trim();
    if (value.isEmpty || value.startsWith('data:')) return '';
    final uri = Uri.tryParse(value);
    if (uri == null) return '';
    final resolved = uri.hasScheme ? uri : Uri.parse(baseUrl).resolve(value);
    if ((resolved.scheme != 'http' && resolved.scheme != 'https') ||
        resolved.host.isEmpty) {
      return '';
    }
    return resolved.toString();
  }
}
