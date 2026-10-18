// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../System/app_storage.dart';

import 'package:flutter/material.dart';
import 'package:v1_game/Modelos/ImgWebScrap.dart';
import 'package:v1_game/Modelos/NoticiaGame.dart';
import 'package:v1_game/Class/wallpapercave_image_cache.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
import 'dart:convert';

import '../Modelos/videoYT.dart';

class WebScrap{
  static final Map<String, Future<List<String>>> _noticiaImageCandidatesCache = {};
  static final Map<String, Future<List<String>>> _articleImageCandidatesCache = {};
  static final List<Completer<void>> _imageSearchWaiters = [];
  static int _activeImageSearches = 0;


  static Map<String, String> noticiaImageHeaders(String articleUrl) {
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          'Chrome/124.0.0.0 Safari/537.36',
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
    };
    final article = Uri.tryParse(articleUrl);
    if (article != null &&
        (article.scheme == 'http' || article.scheme == 'https') &&
        article.host.isNotEmpty) {
      headers['Referer'] = article.toString();
    }
    return headers;
  }

  static String _normalizarUrlImagem(String raw, {Uri? base}) {
    final decoded = _limpaHtml(raw)
        .replaceAll(RegExp(r'&#0*38;', caseSensitive: false), '&')
        .replaceAll(RegExp(r'&#x0*26;', caseSensitive: false), '&');
    if (decoded.isEmpty) return '';
    try {
      final candidate = Uri.tryParse(decoded);
      final resolved = candidate?.hasScheme == true
          ? candidate
          : base?.resolve(decoded);
      if (resolved == null ||
          (resolved.scheme != 'http' && resolved.scheme != 'https') ||
          resolved.host.isEmpty) {
        return '';
      }
      return resolved.toString();
    } catch (_) {
      return '';
    }
  }
 
  
  // Função para pegar os links das imagens com base no nome do jogo
  /// O nome do arquivo carrega o identificador do wallpaper — `wp123` para os
  /// oficiais, `uwp123` para os de usuário — em qualquer tamanho. O que muda é
  /// só a pasta: `wp`, `uwp`, `w400`, `wpt`, `mwp`, `dwp1x`, `fuwp`,
  /// `fuwp-255`, `fuwp-510`… e cada tipo de página usa um conjunto diferente.
  /// Por isso o original se deduz do nome, e não de uma lista de pastas: essa
  /// lista deixava páginas inteiras de busca voltarem vazias.
  static final _nomeDeWallpaper =
      RegExp(r'^(u?wp)\d+\.[a-z0-9]+$', caseSensitive: false);

  /// Endereço do wallpaper quando [raw] é um deles, ou vazio para qualquer
  /// outra imagem da página — logo, ícones de menu, avatares e botões de rede
  /// social não têm esse nome, e somem sem precisar de lista de exclusões.
  /// Com [tamanhoCheio], devolve o arquivo original em vez da miniatura.
  static String _wallpaper(String raw, {required bool tamanhoCheio}) {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.host == 'wallpapercave.com' ||
            uri.host.endsWith('.wallpapercave.com')) ||
        uri.pathSegments.length != 2) {
      return '';
    }
    final arquivo = uri.pathSegments[1];
    final marca = _nomeDeWallpaper.firstMatch(arquivo);
    if (marca == null ||
        RegExp(r'\.(?:webm|mp4)$', caseSensitive: false).hasMatch(arquivo)) {
      return '';
    }
    return Uri(scheme: uri.scheme, host: uri.host, pathSegments: [
      tamanhoCheio ? marca[1]!.toLowerCase() : uri.pathSegments.first,
      arquivo,
    ]).toString();
  }

  /// Toda página do site termina com um bloco "Recent Wallpapers by Our
  /// Community": 28 imagens recentes que nada têm a ver com o que foi buscado.
  /// Elas precisam ficar de fora por dois motivos: enchiam a grade de
  /// resultados alheios, e faziam qualquer busca parecer bem-sucedida — o que
  /// impedia o seletor de encurtar o nome palavra a palavra até achar um
  /// resultado de verdade. Seções como "Related Wallpapers" continuam valendo.
  static final _secaoDaComunidade =
      RegExp(r'recent wallpapers by our community', caseSensitive: false);

  static Set<dom.Element> _imagensDePreenchimento(dom.Document document) {
    final descartadas = <dom.Element>{};
    for (final titulo in document.querySelectorAll('h2')) {
      if (!_secaoDaComunidade.hasMatch(titulo.text)) continue;
      var secao = titulo.parent;
      while (secao != null &&
          !(secao.localName == 'div' && secao.classes.contains('imgrow'))) {
        secao = secao.parent;
      }
      descartadas.addAll((secao ?? titulo.parent)?.querySelectorAll('img') ??
          const <dom.Element>[]);
    }
    return descartadas;
  }

  /// Resolução real declarada pela página de um wallpaper, em `<p
  /// class="resolution">1080x2160</p>`. Nessas páginas o `<img>` principal traz
  /// no `width`/`height` o tamanho em que ele aparece na tela (700x1400), não o
  /// do arquivo — era daí que vinha a resolução errada nas imagens soltas.
  static List<String> _resolucaoDaPagina(dom.Document document) {
    final texto = document.querySelector('p.resolution')?.text.trim() ?? '';
    final partes = RegExp(r'^(\d+)\s*[x×]\s*(\d+)$', caseSensitive: false)
        .firstMatch(texto);
    return partes == null ? const ['', ''] : [partes[1]!, partes[2]!];
  }

  /// Quantas imagens o álbum guarda, quando a miniatura é a capa de um. O
  /// site declara o número em `<div class="aall" photos="60">`; resultados que
  /// são uma imagem solta não têm esse atributo e ficam em zero.
  static int _fotosDoAlbum(dom.Element element) {
    var parente = element.parent;
    while (parente != null) {
      final declarado = parente.attributes['photos'];
      if (declarado != null) return int.tryParse(declarado.trim()) ?? 0;
      if (parente.localName == 'a') break;
      parente = parente.parent;
    }
    return 0;
  }

  /// Página que abre aquele wallpaper, quando a miniatura está dentro de um
  /// link. É o que a tela chama de "pasta".
  static String _pastaDoWallpaper(dynamic element, Uri base) {
    var parent = element.parent;
    while (parent != null && parent.localName != 'a') {
      parent = parent.parent;
    }
    final href = parent?.attributes['href']?.trim() ?? '';
    if (href.isEmpty ||
        RegExp(r'\.(?:jpe?g|png|webp|gif|bmp)(?:[?#].*)?$', caseSensitive: false)
            .hasMatch(href)) {
      return '';
    }
    final pasta = Uri.tryParse(href);
    final resolvida = pasta?.hasScheme == true ? pasta : base.resolve(href);
    if (resolvida == null ||
        (resolvida.scheme != 'http' && resolvida.scheme != 'https') ||
        resolvida.host.isEmpty) {
      return '';
    }
    return resolvida.toString();
  }

  /// Wallpapers de qualquer página do site. A classe do `<img>` muda conforme
  /// a página — `wimg` nas listagens, `wpimg` na página de uma imagem,
  /// `thumbnail` nas capas de álbum e nada nas miniaturas das vizinhas —,
  /// então o que identifica um wallpaper aqui é o nome do arquivo. Filtrar por
  /// uma classe só fazia as páginas de imagem abrirem vazias, mesmo tendo
  /// imagens.
  ///
  /// A listagem fica com as miniaturas que a página entrega, que é o que a
  /// grade precisa; [tamanhoCheio] é para a visão de dentro da pasta, onde a
  /// escolha vai virar a capa do jogo e precisa do arquivo original.
  static List<ImgWebScrap> wallpapersDaPagina(String body, Uri base,
      {bool tamanhoCheio = false}) {
    final document = html.parse(body);
    final preenchimento = _imagensDePreenchimento(document);
    final resolucao = _resolucaoDaPagina(document);
    final vistos = <String>{};
    final lista = <ImgWebScrap>[];
    for (final element in document.querySelectorAll('img')) {
      if (preenchimento.contains(element)) continue;
      final imagem = ImgWebScrap()
        ..fromMapImgFinal(
          element.attributes
              .map((key, value) => MapEntry(key.toString(), value)),
          baseUrl: base.toString(),
        );
      final endereco =
          _wallpaper(imagem.imageUrl, tamanhoCheio: tamanhoCheio);
      if (endereco.isEmpty || !vistos.add(endereco)) continue;
      imagem.imageUrl = endereco;
      imagem.folderUrl = _pastaDoWallpaper(element, base);
      imagem.fotos = _fotosDoAlbum(element);
      // Só a listagem (`wimg`) declara no próprio `<img>` a resolução do
      // arquivo. A imagem principal de uma página (`wpimg`) usa a resolução
      // declarada pela página, e miniaturas ficam sem nenhuma: um campo vazio
      // é melhor do que o tamanho da miniatura passando por resolução.
      if (!element.classes.contains('wimg')) {
        final daPagina = element.classes.contains('wpimg');
        imagem.largura = daPagina ? resolucao[0] : '';
        imagem.altura = daPagina ? resolucao[1] : '';
      }
      lista.add(imagem);
    }
    return lista;
  }

  static Future<List<dynamic>> buscaUsersWalpaperCave(String gameName) async {
    final url = Uri.https('wallpapercave.com', '/search', {'q': gameName.trim()});
    try {
      final response = await WallpapercaveImageCache.get(url).timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode != 200) {
        return ['Erro ao buscar dados. Status: ${response.statusCode}', <ImgWebScrap>[]];
      }

      final list = wallpapersDaPagina(
          utf8.decode(response.bodyBytes, allowMalformed: true), url);
      final content = list.isEmpty
          ? 'Nenhuma imagem encontrada para "$gameName".'
          : 'Imagens encontradas: ${list.length}';
      return [content, list];
    } catch (error) {
      return ['Erro ao buscar dados: $error', <ImgWebScrap>[]];
    }
  }

  static Future<List<dynamic>> buscaImgsWalpaperCave(String gameId) async {
    String content = '';
    List<ImgWebScrap> list = [];
    final rawPath = gameId.trim();
    final parsedPath = Uri.tryParse(rawPath);
    final url = parsedPath?.hasScheme == true
        ? parsedPath!
        : Uri.parse('https://wallpapercave.com/').resolve(
            rawPath.startsWith('/') ? rawPath : '/$rawPath',
          );
    
    try {
      final response = await WallpapercaveImageCache.get(url).timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode == 200) {
        list = wallpapersDaPagina(
            utf8.decode(response.bodyBytes, allowMalformed: true), url,
            tamanhoCheio: true);
        content = list.isEmpty
            ? 'Nenhuma imagem encontrada para "$gameId".'
            : 'Imagens encontradas: ${list.length}';
      } else {
        content = 'Erro ao buscar dados. Status: ${response.statusCode}';
      }
    } catch (e) {
      content = 'Exceção ao buscar dados: $e';
    }
    debugPrint('Wallpapers em $url: $content');
    return [content, list];
  }


  static Future<String> downloadImage(String imageUrl, String nomeGame) async {
    try {
      final uri = Uri.tryParse(imageUrl);
      if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
        return 'Erro:: URL da imagem inv\u00e1lida.';
      }
      final cachedImage = await WallpapercaveImageCache.manager
          .getSingleFile(imageUrl, headers: WallpapercaveImageCache.headers)
          .timeout(const Duration(seconds: 60));
      final imageBytes = await cachedImage.readAsBytes();
      if (!_isSupportedImageBytes(imageBytes)) {
        return 'Erro:: O servidor n\u00e3o retornou uma imagem compat\u00edvel.';
      }

      final extencao = _imageExtensionFromBytes(imageBytes);
      final directoryPath = p.join(AppStorage.root.path, 'FundoGamesV1');
      final safeName = nomeGame.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
          .replaceAll(RegExp(r'[. ]+$'), '');
      final filePath = p.join(directoryPath,
          'game-${safeName.isEmpty ? 'imagem' : safeName}$extencao');

      final directory = Directory(directoryPath);
      await ensureWritableDirectory(directory);
      if (!await directory.exists()) await directory.create(recursive: true);

      final file = File(filePath);
      await file.writeAsBytes(imageBytes, flush: true);
      await FileImage(file).evict();
      debugPrint('Imagem salva em: $filePath');
      return filePath;
    } catch (error) {
      debugPrint('Erro ao salvar a imagem: $error');
      return 'Erro:: ao salvar a imagem: $error';
    }
  }

  static bool _isSupportedImageBytes(List<int> bytes) =>
      _imageExtensionFromBytes(bytes).isNotEmpty;

  static String _imageExtensionFromBytes(List<int> bytes) {
    if (bytes.length >= 3 && bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) return '.jpg';
    if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4e && bytes[3] == 0x47) return '.png';
    if (bytes.length >= 6) {
      final signature = ascii.decode(bytes.take(6).toList(), allowInvalid: true);
      if (signature == 'GIF87a' || signature == 'GIF89a') return '.gif';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.take(4).toList(), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.skip(8).take(4).toList(), allowInvalid: true) == 'WEBP') {
      return '.webp';
    }
    if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4d) return '.bmp';
    return '';
  }

  static Future<List<VideoYT>> buscaVideosYT(String query, String nomeJogo) async {
    List<VideoYT> listVideosFinal = [];
    try{ 
      List<VideoYT> listVideos = [];    
      final url = 'https://www.youtube.com/results?search_query=$query';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final htmlContent = utf8.decode(response.bodyBytes, allowMalformed: true);
        final videoMatches = RegExp(r'"title":{"runs":\[{"text":"([^"]+)"\}.*?"videoId":"([^"]+)"').allMatches(htmlContent);
            
        listVideos = videoMatches.map((match) {
          VideoYT video = VideoYT();
          final videoId = match.group(2)!;
          video.nomeGame = nomeJogo;
          video.titulo = match.group(1)!;
          video.urlVideo = 'https://www.youtube.com/watch?v=$videoId';
          video.videoID = videoId;
          video.capaP = 'https://img.youtube.com/vi/$videoId/default.jpg';
          video.capaM = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
          video.capaG = 'https://img.youtube.com/vi/$videoId/0.jpg';
          video.canal = '';
          video.descricao = '';
          video.data = '';
          return video;
        }).toList();

        
        
        
      } else {
        throw Exception('Falha ao carregar a página do YouTube');
      }
      listVideosFinal = limpaUrlsRepetidas(listVideos);
    }catch(e){debugPrint(e.toString());}
    

    return listVideosFinal;
  }

  static List<VideoYT> limpaUrlsRepetidas(List<VideoYT>listVideos){
    // Conjunto para armazenar URLs únicas
    Set<String> urlsVistas = {};

    // Filtra a lista original, mantendo apenas vídeos com URLs únicas
    List<VideoYT> listaFiltrada = listVideos.where((video) {
    // Tenta adicionar a URL ao conjunto. Se já existir, add retorna false.
    return urlsVistas.add(video.urlVideo);
    }).toList();

    // A lista filtrada agora contém apenas vídeos com URLs únicas
    // debugPrint('Total de vídeos após remoção de duplicatas: ${listaFiltrada.length}');
    return listaFiltrada;
  }

  /// Decodifica entidades HTML e remove tags
  static String _limpaHtml(String raw) {
    // 1ª passagem: decodifica entidades para obter o HTML real
    var s = raw
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&nbsp;', ' ');
    // Remove tags HTML
    s = s.replaceAll(RegExp(r'<[^>]*>'), '');
    // 2ª passagem: entidades que sobraram após decode duplo
    s = s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&#39;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&nbsp;', ' ');
    // Remove espaços múltiplos e quebras de linha excessivas
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ');
    return s.trim();
  }

  /// Busca uma imagem de reserva no Google Images quando o feed não fornece
  /// uma URL utilizável.
  static Future<String> buscaImagemGoogle(String query) async {
    final images = await _buscarImagensGoogle(query);
    return images.isEmpty ? '' : images.first;
  }

  /// Reúne várias imagens do artigo e da busca para tentar alternativas se
  /// algum servidor bloquear a primeira URL.
  static Future<List<String>> buscarCandidatasImagemNoticia(
      NoticiaGame noticia) {
    final key = '${noticia.url.trim()}|${noticia.titulo.trim()}|${noticia.veiculo.trim()}'
        .toLowerCase();
    if (key == '||') return Future.value(const []);
    final cached = _noticiaImageCandidatesCache[key];
    if (cached != null) return cached;
    if (_noticiaImageCandidatesCache.length >= 256) {
      _noticiaImageCandidatesCache.remove(_noticiaImageCandidatesCache.keys.first);
    }

    final lookup = () async {
      final articleImages =
          (await _buscarImagensArtigoCache(noticia.url)).take(6).toList();
      final query = [noticia.titulo.trim(), noticia.veiculo.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ');
      var searchImages = <String>[];
      if (query.isNotEmpty) {
        await _acquireImageSearchSlot();
        try {
          searchImages = await _buscarImagensGoogle(query);
        } finally {
          _releaseImageSearchSlot();
        }
      }
      return {...articleImages, ...searchImages}.take(12).toList();
    }();
    _noticiaImageCandidatesCache[key] = lookup;
    return lookup.then((images) {
      if (images.isEmpty && identical(_noticiaImageCandidatesCache[key], lookup)) {
        _noticiaImageCandidatesCache.remove(key);
      }
      return images;
    });
  }

  static Future<List<String>> _buscarImagensGoogle(String query) async {
    try {
      final searchUrl = Uri.https('www.google.com', '/search', {
        'q': query,
        'tbm': 'isch',
        'hl': 'pt-BR',
        'gl': 'BR',
      }).toString();
      debugPrint('=== buscaImagemGoogle URL: $searchUrl');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 8)
        ..userAgent =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            'Chrome/124.0.0.0 Safari/537.36';

      final req = await client.getUrl(Uri.parse(searchUrl));
      req.headers.set('Accept-Language', 'pt-BR,pt;q=0.9');
      req.headers.set('Accept', 'text/html,application/xhtml+xml');
      final resp = await req.close().timeout(const Duration(seconds: 10));

      debugPrint('=== buscaImagemGoogle status: ${resp.statusCode}');
      if (resp.statusCode != 200) {
        client.close(force: true);
        return const [];
      }

      final bytes = <int>[];
      await for (final chunk in resp) {
        bytes.addAll(chunk);
        if (bytes.length >= 262144) break;
      }
      client.close(force: true);

      final body = utf8.decode(bytes, allowMalformed: true);

      // Google Images inclui a URL original no campo "ou". Ela pode ter
      // escapes JSON e parâmetros depois da extensão do arquivo.
      final jsonImgMatches = RegExp(
        r'"ou"\s*:\s*"((?:\\.|[^"\\])*)"',
        caseSensitive: false,
      ).allMatches(body);

      final originals = <String>[];
      final thumbnails = <String>[];
      for (final m in jsonImgMatches) {
        final raw = m.group(1) ?? '';
        final url = _normalizarUrlImagem(_decodeJsonString(raw));
        if (url.isEmpty) continue;
        final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
        if (host.contains('google') || host.contains('gstatic')) {
          thumbnails.add(url);
        } else {
          originals.add(url);
        }
      }

      // Alguns resultados expõem apenas o src da miniatura; use-o como reserva.
      final imgTagMatches = RegExp(
        r"""<(?:img|source)\b[^>]*(?:src|data-src)=["']([^"']+)["']""",
        caseSensitive: false,
      ).allMatches(body);

      for (final m in imgTagMatches) {
        final raw = m.group(1) ?? '';
        final url = _normalizarUrlImagem(_decodeJsonString(raw));
        if (url.isEmpty) continue;
        final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
        if (host.contains('google') || host.contains('gstatic')) {
          thumbnails.add(url);
        } else {
          originals.add(url);
        }
      }

      final candidates = {...originals, ...thumbnails}.take(12).toList();
      debugPrint('=== buscaImagemGoogle candidatas: ${candidates.length}');
      return candidates;
    } catch (e) {
      debugPrint('=== buscaImagemGoogle ERRO: $e');
      return const [];
    }
  }

  static Future<String> buscaImagemAlternativaNoticia(
      String titulo, String veiculo) {
    return buscarCandidatasImagemNoticia(NoticiaGame(
      titulo: titulo,
      veiculo: veiculo,
    )).then((images) => images.isEmpty ? '' : images.first);
  }

  static Future<List<String>> _buscarImagensArtigoCache(String url) {
    final key = url.trim();
    if (key.isEmpty) return Future.value(const []);
    final cached = _articleImageCandidatesCache[key];
    if (cached != null) return cached;
    if (_articleImageCandidatesCache.length >= 256) {
      _articleImageCandidatesCache.remove(_articleImageCandidatesCache.keys.first);
    }
    final lookup = _buscarImagensArtigo(key);
    _articleImageCandidatesCache[key] = lookup;
    return lookup.then((images) {
      if (images.isEmpty && identical(_articleImageCandidatesCache[key], lookup)) {
        _articleImageCandidatesCache.remove(key);
      }
      return images;
    });
  }

  static Future<List<String>> _buscarImagensArtigo(String articleUrl) async {
    try {
      final response = await http.get(Uri.parse(articleUrl), headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            'Chrome/124.0.0.0 Safari/537.36',
        'Accept-Language': 'pt-BR,pt;q=0.9',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return const [];

      final bytes = response.bodyBytes;
      final source = utf8.decode(
          bytes.length > 524288 ? bytes.sublist(0, 524288) : bytes,
          allowMalformed: true);
      final document = html.parse(source);
      var base = response.request?.url ?? Uri.tryParse(articleUrl);
      final metadata = <String>[];
      final inlineImages = <({String url, int score})>[];
      void addMetadata(String raw) {
        final url = _normalizarUrlImagem(raw, base: base);
        if (url.isNotEmpty) metadata.add(url);
      }

      for (final link in document.querySelectorAll('link[href]')) {
        final rel = (link.attributes['rel'] ?? '').toLowerCase().split(RegExp(r'\s+'));
        if (!rel.contains('canonical')) continue;
        final canonical = _normalizarUrlImagem(link.attributes['href'] ?? '', base: base);
        if (canonical.isNotEmpty) {
          base = Uri.tryParse(canonical) ?? base;
          break;
        }
      }

      for (final meta in document.querySelectorAll('meta')) {
        final property = (meta.attributes['property'] ?? '').toLowerCase();
        final name = (meta.attributes['name'] ?? '').toLowerCase();
        final itemprop = (meta.attributes['itemprop'] ?? '').toLowerCase();
        if (const {'og:image', 'og:image:url', 'og:image:secure_url'}
                .contains(property) ||
            const {'twitter:image', 'twitter:image:src'}.contains(name) ||
            itemprop == 'image') {
          addMetadata(meta.attributes['content'] ?? '');
        }
      }
      for (final link in document.querySelectorAll('link[href]')) {
        final rel = (link.attributes['rel'] ?? '').toLowerCase().split(RegExp(r'\s+'));
        if (rel.contains('image_src')) addMetadata(link.attributes['href'] ?? '');
      }
      for (final script in document.querySelectorAll('script[type="application/ld+json"]')) {
        try {
          _collectStructuredImages(jsonDecode(script.text), addMetadata);
        } catch (_) {}
      }

      for (final image in document.querySelectorAll('img, picture source')) {
        final attributes = image.attributes;
        final alt = [attributes['alt'] ?? '', attributes['title'] ?? '',
          attributes['class'] ?? '', attributes['id'] ?? ''].join(' ').toLowerCase();
        if (RegExp(r'logo|avatar|icon|sprite|tracking|pixel|advert|share').hasMatch(alt)) continue;
        final width = int.tryParse(attributes['width'] ?? '') ?? 0;
        final height = int.tryParse(attributes['height'] ?? '') ?? 0;
        if ((width > 0 && width < 200) || (height > 0 && height < 120)) continue;
        final score = (width * height).clamp(0, 20000000) +
            (alt.contains('article') || alt.contains('news') ? 100000 : 0);
        final sources = [attributes['src'] ?? '', attributes['data-src'] ?? '',
          attributes['data-original'] ?? '', attributes['data-lazy-src'] ?? '',
          _largestSrcset(attributes['srcset'] ?? '')];
        for (final raw in sources) {
          final url = _normalizarUrlImagem(raw, base: base);
          if (url.isNotEmpty) inlineImages.add((url: url, score: score));
        }
      }
      inlineImages.sort((a, b) => b.score.compareTo(a.score));
      return {
        ...metadata,
        ...inlineImages.map((image) => image.url).where(_looksLikeUsableImageUrl),
      }.where(_looksLikeUsableImageUrl).take(10).toList();
    } catch (error) {
      debugPrint('=== busca de imagens no artigo falhou: $error');
      return const [];
    }
  }

  static void _collectStructuredImages(Object? value, void Function(String) add) {
    if (value is List) {
      for (final item in value) { _collectStructuredImages(item, add); }
    } else if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase();
        final candidate = entry.value;
        if (key == 'image' || key == 'thumbnailurl') {
          if (candidate is String) add(candidate);
          if (candidate is Map) {
            final imageUrl = candidate['url'] ?? candidate['contentUrl'];
            if (imageUrl is String) add(imageUrl);
          }
          if (candidate is List) _collectStructuredImages(candidate, add);
        } else if (candidate is Map || candidate is List) {
          _collectStructuredImages(candidate, add);
        }
      }
    }
  }

  static String _largestSrcset(String srcset) {
    if (srcset.trim().isEmpty) return '';
    final options = srcset.split(',').map((option) {
      final parts = option.trim().split(RegExp(r'\s+'));
      final width = parts.length > 1
          ? int.tryParse(parts.last.replaceAll(RegExp(r'\D'), '')) ?? 0
          : 0;
      return (url: parts.isEmpty ? '' : parts.first, width: width);
    }).toList()..sort((a, b) => b.width.compareTo(a.width));
    return options.first.url;
  }

  static bool _looksLikeUsableImageUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return !host.contains('doubleclick') &&
        !host.contains('googlesyndication') &&
        !RegExp(r'\.svg$').hasMatch(uri.path.toLowerCase());
  }

  static Future<void> _acquireImageSearchSlot() {
    if (_activeImageSearches < 3) {
      _activeImageSearches++;
      return Future.value();
    }
    final waiter = Completer<void>();
    _imageSearchWaiters.add(waiter);
    return waiter.future;
  }

  static void _releaseImageSearchSlot() {
    if (_imageSearchWaiters.isNotEmpty) {
      _imageSearchWaiters.removeAt(0).complete();
    } else {
      _activeImageSearches--;
    }
  }

  static String _decodeJsonString(String value) {
    try {
      final decoded = jsonDecode('"$value"');
      if (decoded is String) return decoded;
    } catch (_) {}
    return value.replaceAll(r'\/', '/');
  }

  /// Busca notícias sobre um jogo via Google News RSS (em português)
  static Future<List<NoticiaGame>> buscaNoticiasGame(String gameName) async {
    try {
      // Busca em português: nome do jogo + termos PT
      final query = Uri.encodeComponent(gameName);
      final uri = Uri.parse(
        'https://news.google.com/rss/search?q=$query&hl=pt-BR&gl=BR&ceid=BR:pt-419',
      );
      final resp = await http
          .get(uri, headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            'Accept-Language': 'pt-BR,pt;q=0.9',
          })
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode != 200) return [];

      final body = utf8.decode(resp.bodyBytes, allowMalformed: true);
      final noticias = <NoticiaGame>[];

      final itemMatches = RegExp(r'<item>([\s\S]*?)</item>').allMatches(body);
      bool firstPrinted = false;

      for (final m in itemMatches.take(12)) {
        final s = m.group(1) ?? '';
        if (!firstPrinted) {
          firstPrinted = true;
          // debugPrint('=== RAW ITEM[0] ===\n$s\n=== FIM RAW ===');
        }

        String ext(String tag) => RegExp(
              '<$tag[^>]*>(?:<!\\[CDATA\\[)?([\\s\\S]*?)(?:\\]\\]>)?</$tag>',
            ).firstMatch(s)?.group(1)?.trim() ?? '';

        final titulo = _limpaHtml(ext('title'));
        if (titulo.isEmpty) continue;

        final descRaw = ext('description');
        final cleanDesc = _limpaHtml(descRaw);
        final descMarkup = RegExp(r'&lt;|&#x0*3c;', caseSensitive: false)
                .hasMatch(descRaw)
            ? html.parseFragment(descRaw).text
            : descRaw;
        final descriptionDocument = html.parseFragment(descMarkup);

        // Extrai URL real do artigo a partir dos links dentro do <description>
        // O Google News RSS embute: <a href="https://site.com/artigo">
        final linkNoDesc = descriptionDocument
            .querySelectorAll('a[href]')
            .map((anchor) => anchor.attributes['href'] ?? '')
            .firstWhere((href) {
              final parsed = Uri.tryParse(href);
              return parsed != null &&
                  (parsed.scheme == 'http' || parsed.scheme == 'https') &&
                  parsed.host.isNotEmpty &&
                  parsed.host.toLowerCase() != 'news.google.com';
            }, orElse: () => '');

        final linkRaw = RegExp(r'<link[^>]*>([^<]+)</link>').firstMatch(s)?.group(1)?.trim() ?? '';
        final guid    = ext('guid');
        final urlBase = linkRaw.startsWith('http')
            ? linkRaw
            : (guid.startsWith('http') ? guid : 'https://news.google.com/articles/$guid');

        // Prefere URL real (sem redirect do Google)
        final url = linkNoDesc.isNotEmpty ? linkNoDesc : urlBase;

        // Imagem do RSS: media:thumbnail > media:content > img no description
        final mediaThumbnail = RegExp(
          r'''<media:thumbnail\b[^>]*\burl\s*=\s*["']([^"']+)["']''',
          caseSensitive: false,
        ).firstMatch(s)?.group(1) ?? '';
        final mediaContentTag = RegExp(
          r'<media:content\b([^>]*)>',
          caseSensitive: false,
        ).firstMatch(s)?.group(1) ?? '';
        final mediaContentUrl = RegExp(
          r'''\burl\s*=\s*["']([^"']+)["']''',
          caseSensitive: false,
        ).firstMatch(mediaContentTag)?.group(1) ?? '';
        final mediaContentType = RegExp(
          r'''\btype\s*=\s*["']([^"']+)["']''',
          caseSensitive: false,
        ).firstMatch(mediaContentTag)?.group(1) ?? '';
        final mediaContentMedium = RegExp(
          r'''\bmedium\s*=\s*["']([^"']+)["']''',
          caseSensitive: false,
        ).firstMatch(mediaContentTag)?.group(1) ?? '';
        final mediaContentUri = Uri.tryParse(
            _limpaHtml(mediaContentUrl));
        final hasImageMedia = mediaContentType.toLowerCase().startsWith('image/') ||
            mediaContentMedium.toLowerCase() == 'image' ||
            RegExp(r'\.(?:jpe?g|png|webp)$', caseSensitive: false)
                .hasMatch(mediaContentUri?.path ?? '');
        final mediaContent = hasImageMedia ? mediaContentUrl : '';
        final descriptionImage = descriptionDocument.querySelector('img');
        final imgNoDesc = descriptionImage?.attributes['src'] ??
            descriptionImage?.attributes['data-src'] ??
            '';

        final imgRaw = mediaThumbnail.isNotEmpty
            ? mediaThumbnail
            : (mediaContent.isNotEmpty ? mediaContent : imgNoDesc);
        final imgRss = _normalizarUrlImagem(imgRaw, base: Uri.tryParse(url));

        noticias.add(NoticiaGame(
          titulo: titulo,
          veiculo: _limpaHtml(ext('source')),
          descricao: cleanDesc,
          url: url,
          dataStr: ext('pubDate'),
          imgUrl: imgRss,
        ));
      }

      // if (noticias.isNotEmpty) {
      //   final n = noticias.first;
      //   debugPrint('=== NOTÍCIA[0] titulo: ${n.titulo}');
      //   debugPrint('=== NOTÍCIA[0] url: ${n.url}');
      //   debugPrint('=== NOTÍCIA[0] imgUrl: ${n.imgUrl}');
      //   debugPrint('=== NOTÍCIA[0] veiculo: ${n.veiculo}');
      // }

      // Busca og:image de cada artigo em paralelo
      // Se o RSS já trouxe imagem, pula o fetch do artigo
      final imgFutures = noticias.map((n) async {
        final rssImage = _normalizarUrlImagem(n.imgUrl);
        if (rssImage.isNotEmpty) return rssImage;
        return _buscarOgImage(n.url);
      }).toList();
      final imgs = await Future.wait(imgFutures);

      return List.generate(noticias.length, (i) {
        final img = _normalizarUrlImagem(imgs[i]).isNotEmpty
            ? _normalizarUrlImagem(imgs[i])
            : _normalizarUrlImagem(noticias[i].imgUrl);
        return NoticiaGame(
          titulo: noticias[i].titulo,
          veiculo: noticias[i].veiculo,
          descricao: noticias[i].descricao,
          url: noticias[i].url,
          dataStr: noticias[i].dataStr,
          imgUrl: img,
        );
      });
    } catch (e) {
      debugPrint('Erro noticias: $e');
      return [];
    }
  }

  /// Acessa o artigo e extrai og:image / twitter:image do HTML
  static Future<String> _buscarOgImage(String urlInicial) async {
    final candidates = await _buscarImagensArtigoCache(urlInicial);
    return candidates.isEmpty ? '' : candidates.first;
  }

  /// Retorna um emoji condizente com o conteúdo do título
  static String _emojiParaTitulo(String titulo) {
    final t = titulo.toLowerCase();
    if (t.contains('trailer') || t.contains('vídeo') || t.contains('video') || t.contains('cinética')) return '🎬';
    if (t.contains('atualização') || t.contains('update') || t.contains('patch') || t.contains('versão')) return '🔄';
    if (t.contains('lançamento') || t.contains('estreia') || t.contains('launch') || t.contains('chegou') || t.contains('chegando')) return '🚀';
    if (t.contains('dlc') || t.contains('expansão') || t.contains('expansion') || t.contains('conteúdo')) return '📦';
    if (t.contains('review') || t.contains('análise') || t.contains('nota') || t.contains('avaliação') || t.contains('crítica')) return '⭐';
    if (t.contains('esport') || t.contains('torneio') || t.contains('campeonato') || t.contains('mundial') || t.contains('competiti')) return '🏆';
    if (t.contains('bug') || t.contains('problema') || t.contains('falha') || t.contains('crash') || t.contains('erro')) return '🐛';
    if (t.contains('multiplayer') || t.contains('online') || t.contains('servidor') || t.contains('coop') || t.contains('co-op')) return '🌐';
    if (t.contains('história') || t.contains('enredo') || t.contains('story') || t.contains('personagem') || t.contains('narrativa')) return '📖';
    if (t.contains('batalha') || t.contains('guerra') || t.contains('fight') || t.contains('combate') || t.contains('pvp')) return '⚔️';
    if (t.contains('gratuito') || t.contains('grátis') || t.contains('free') || t.contains('de graça')) return '🎁';
    if (t.contains('download') || t.contains('beta') || t.contains('acesso antecipado') || t.contains('early access')) return '💾';
    if (t.contains('ban') || t.contains('cheat') || t.contains('hack') || t.contains('trapaça')) return '🚫';
    if (t.contains('música') || t.contains('trilha') || t.contains('soundtrack') || t.contains('sônico')) return '🎵';
    if (t.contains('arte') || t.contains('concept') || t.contains('visual') || t.contains('gráfico')) return '🎨';
    if (t.contains('mundo') || t.contains('mapa') || t.contains('aberto') || t.contains('open world')) return '🌍';
    if (t.contains('novo') || t.contains('novo jogo') || t.contains('anúnciou') || t.contains('anuncia')) return '🌟';
    return '🎮';
  }

  static String emojiParaTitulo(String titulo) => _emojiParaTitulo(titulo);
}
