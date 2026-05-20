// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:v1_game/Modelos/ImgWebScrap.dart';
import 'package:v1_game/Modelos/NoticiaGame.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'dart:convert';

import '../Modelos/videoYT.dart';

class WebScrap{
 
  
  // Função para pegar os links das imagens com base no nome do jogo
  static Future<List<dynamic>> buscaUsersWalpaperCave(String gameName) async {
    String content = '';
    List<ImgWebScrap> list = [];
    // Cria a URL de busca dinâmica para Wallpapercave
    final url = Uri.parse('https://wallpapercave.com/search?q=$gameName');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final bodyStr = utf8.decode(response.bodyBytes, allowMalformed: true);
      final document = html.parse(bodyStr);
      // Seleciona todas as tags <img> e filtra os links das imagens
      final arquivo = document.querySelectorAll('img');
      list = arquivo.map((e) {
        final title = e.attributes['alt'] ?? ''; // Extrair o título (se disponível)
        final imageUrl = e.attributes['src'] ?? ''; // Extrair o link da imagem
        final tipo = e.attributes['class']??""; // Extrai o Tipo

        return ImgWebScrap(title: title, imageUrl: imageUrl,tipo: tipo);
      }).where((data) => data.imageUrl.isNotEmpty && data.imageUrl.contains("https")).toList();

      if (list.isEmpty) content = 'Nenhuma imagem encontrada para "$gameName".';
      if (list.isNotEmpty) content = 'Imagens encontradas: ${list.length}';
        
    } else {
      content = 'Erro ao buscar dados.';     
    }
    return [content,list];
  }

  static Future<List<dynamic>> buscaImgsWalpaperCave(String gameId) async {
    String content = '';
    List<ImgWebScrap> list = [];
    final url = Uri.parse('https://wallpapercave.com/$gameId');
    
    debugPrint('========================================');
    debugPrint('WEBSCRAP - BUSCA DE IMAGENS');
    debugPrint('URL Completa: ${url.toString()}');
    debugPrint('GameId: $gameId');
    
    try {
      final response = await http.get(url);
      debugPrint('Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final bodyStr = utf8.decode(response.bodyBytes, allowMalformed: true);
        final document = html.parse(bodyStr);
        // Seleciona todas as tags <img> e filtra os links das imagens
        final arquivo = document.querySelectorAll('img');
        debugPrint('Total de tags <img> encontradas: ${arquivo.length}');
        
        list = arquivo.map((e) {
          ImgWebScrap imgDados = ImgWebScrap();
          imgDados.fromMapImgFinal(e.attributes);
          return imgDados;
        }).where((item) {
          bool valido = item.imageUrl.isNotEmpty && 
                       item.tipo == "wimg" && 
                       !item.imageUrl.contains(".webm");
          
          if (!valido && item.imageUrl.isNotEmpty) {
            debugPrint('Imagem filtrada - URL: ${item.imageUrl}, Tipo: ${item.tipo}');
          }
          
          return valido;
        }).toList();
        
        if (list.isEmpty) {
          content = 'Nenhuma imagem encontrada para "$gameId".';
          debugPrint('AVISO: Nenhuma imagem válida após filtragem');
        } else {
          content = 'Imagens encontradas: ${list.length}';
          debugPrint('Imagens válidas encontradas: ${list.length}');
          debugPrint('Exemplo de URL: ${list.first.imageUrl}');
        }

      } else {
        content = 'Erro ao buscar dados. Status: ${response.statusCode}';
        debugPrint('ERRO: Status code diferente de 200');
      }
    } catch (e) {
      content = 'Exceção ao buscar dados: $e';
      debugPrint('EXCEÇÃO durante busca: $e');
    }
    
    debugPrint('========================================');
    return [content, list];
  }


  static Future<String> downloadImage(String imageUrl, String nomeGame) async {
    String msg = "";
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        String extencao = imageUrl.split('.').last;
        const  directoryPath = 'C:\\Users\\Public\\Pictures\\FundoGamesV1';
        String  filePath = '$directoryPath\\$nomeGame.$extencao';

        final directory = Directory(directoryPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        msg = filePath;
        debugPrint('Imagem salva em: $filePath');
      } else {
        msg = "Erro ao baixar a imagem. Código: ${response.statusCode}";
        debugPrint('Erro ao baixar a imagem. Código: ${response.statusCode}');
      }
    } catch (e) {
      msg = "Erro:: ao salvar a imagem: $e";
      debugPrint('Erro ao salvar a imagem: $e');
    }
    return msg;
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

  /// Busca a primeira imagem válida (jpg/png/webp) via Google Images
  /// Busca a primeira imagem útil via pesquisa normal do Google (sem tbm=isch).
  /// Estratégia: abre a página de resultados e extrai a primeira og:image / src
  /// de imagem que aparecer nos links de notícias embarcados no HTML.
  static Future<String> buscaImagemGoogle(String query) async {
    try {
      final q = Uri.encodeComponent(query);
      // Busca normal do Google — traz snippets de notícias com thumbs
      final searchUrl = 'https://www.google.com/search?q=$q&hl=pt-BR&gl=BR&num=5';
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

      final bytes = <int>[];
      await for (final chunk in resp) {
        bytes.addAll(chunk);
        if (bytes.length >= 32768) break; // 32KB — suficiente para snippets
      }
      client.close();

      final body = utf8.decode(bytes, allowMalformed: true);

      // 1ª tentativa: URLs de imagem embutidas nos dados JSON do Google
      // O Google embute thumbs como: "ou":"https://...jpg"  ou  s="https://...jpg"
      final jsonImgMatches = RegExp(
        r'"(?:ou|ru|src)"\s*:\s*"(https?://[^"]+\.(?:jpg|jpeg|png|webp))"',
        caseSensitive: false,
      ).allMatches(body);

      String? thumb;
      for (final m in jsonImgMatches) {
        final url = m.group(1) ?? '';
        final isThumb = url.contains('encrypted-tbn') || url.contains('gstatic.com/images');
        if (!isThumb) {
          debugPrint('=== buscaImagemGoogle JSON ESCOLHIDA: $url');
          return url;
        }
        thumb ??= url;
      }

      // 2ª tentativa: qualquer src de <img> no HTML com extensão conhecida
      final imgTagMatches = RegExp(
        r"""<img[^>]+src=["'](https?://[^"']+\.(?:jpg|jpeg|png|webp))["']""",
        caseSensitive: false,
      ).allMatches(body);

      for (final m in imgTagMatches) {
        final url = m.group(1) ?? '';
        if (!url.contains('google.com') && !url.contains('gstatic')) {
          debugPrint('=== buscaImagemGoogle IMG TAG: $url');
          return url;
        }
        thumb ??= url;
      }

      // 3ª tentativa: encrypted-tbn (thumb do Google) como último recurso
      if (thumb != null) {
        debugPrint('=== buscaImagemGoogle THUMB: $thumb');
        return thumb;
      }

      debugPrint('=== buscaImagemGoogle: nenhuma imagem encontrada');
      return '';
    } catch (e) {
      debugPrint('=== buscaImagemGoogle ERRO: $e');
      return '';
    }
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

        // Extrai URL real do artigo a partir dos links dentro do <description>
        // O Google News RSS embute: <a href="https://site.com/artigo">
        final linkNoDesc = RegExp(
          r'href="(https?://(?!news\.google\.com)[^"]+)"',
        ).firstMatch(descRaw)?.group(1) ?? '';

        final linkRaw = RegExp(r'<link[^>]*>([^<]+)</link>').firstMatch(s)?.group(1)?.trim() ?? '';
        final guid    = ext('guid');
        final urlBase = linkRaw.startsWith('http')
            ? linkRaw
            : (guid.startsWith('http') ? guid : 'https://news.google.com/articles/$guid');

        // Prefere URL real (sem redirect do Google)
        final url = linkNoDesc.isNotEmpty ? linkNoDesc : urlBase;

        // Imagem do RSS: media:thumbnail > media:content > img no description
        final mediaThumbnail = RegExp(
          r'<media:thumbnail[^>]+url="(https?://[^"]+)"',
        ).firstMatch(s)?.group(1) ?? '';
        final mediaContent = RegExp(
          r'<media:content[^>]+url="(https?://[^"]+\.(?:jpg|jpeg|png|webp))"',
          caseSensitive: false,
        ).firstMatch(s)?.group(1) ?? '';
        final imgNoDesc = RegExp(
          r'<img[^>]+src="(https?://[^"]+)"',
        ).firstMatch(descRaw)?.group(1) ?? '';

        final imgRss = mediaThumbnail.isNotEmpty
            ? mediaThumbnail
            : (mediaContent.isNotEmpty ? mediaContent : imgNoDesc);

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
        if (n.imgUrl.startsWith('http')) return n.imgUrl;
        return _buscarOgImage(n.url);
      }).toList();
      final imgs = await Future.wait(imgFutures);

      return List.generate(noticias.length, (i) {
        final img = imgs[i].isNotEmpty ? imgs[i] : (noticias[i].imgUrl.startsWith('http') ? noticias[i].imgUrl : '');
        return NoticiaGame(
          titulo: noticias[i].titulo,
          veiculo: noticias[i].veiculo,
          descricao: noticias[i].descricao,
          url: noticias[i].url,
          dataStr: noticias[i].dataStr,
          imgUrl: img.isNotEmpty ? img : _emojiParaTitulo(noticias[i].titulo),
        );
      });
    } catch (e) {
      debugPrint('Erro noticias: $e');
      return [];
    }
  }

  /// Acessa o artigo e extrai og:image / twitter:image do HTML
  static Future<String> _buscarOgImage(String urlInicial) async {
    if (urlInicial.isEmpty) return '';
    try {
      // http package segue redirects automaticamente (até 5 saltos)
      final resp = await http.get(
        Uri.parse(urlInicial),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
              'Chrome/124.0.0.0 Safari/537.36',
          'Accept-Language': 'pt-BR,pt;q=0.9',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('=== ogImage [${resp.statusCode}] $urlInicial');
      if (resp.statusCode != 200) return '';

      // Lê apenas os primeiros 16KB — o <head> sempre está no início
      final snippet = utf8.decode(
        resp.bodyBytes.length > 16384
            ? resp.bodyBytes.sublist(0, 16384)
            : resp.bodyBytes,
        allowMalformed: true,
      );

      // 1ª: HTML parser
      final doc = html.parse(snippet);
      for (final meta in doc.querySelectorAll('meta')) {
        final prop    = meta.attributes['property'] ?? '';
        final name    = meta.attributes['name']     ?? '';
        final content = meta.attributes['content']  ?? '';
        if ((prop == 'og:image' ||
                prop == 'og:image:url' ||
                name == 'twitter:image' ||
                name == 'twitter:image:src') &&
            content.startsWith('http')) {
          debugPrint('=== ogImage OK (parser): $content');
          return content;
        }
      }

      // 2ª: regex — property/name antes ou depois de content
      final patterns = [
        RegExp(
            r'''<meta\s[^>]*property=["']og:image["'][^>]*content=["'](https?://[^"']+)["']''',
            caseSensitive: false),
        RegExp(
            r'''<meta\s[^>]*content=["'](https?://[^"']+)["'][^>]*property=["']og:image["']''',
            caseSensitive: false),
        RegExp(
            r'''<meta\s[^>]*name=["']twitter:image[^"']*["'][^>]*content=["'](https?://[^"']+)["']''',
            caseSensitive: false),
        RegExp(
            r'''<meta\s[^>]*content=["'](https?://[^"']+)["'][^>]*name=["']twitter:image''',
            caseSensitive: false),
      ];

      for (final pattern in patterns) {
        final url = pattern.firstMatch(snippet)?.group(1) ?? '';
        if (url.startsWith('http')) {
          debugPrint('=== ogImage OK (regex): $url');
          return url;
        }
      }

      // 3ª: primeira <img> no corpo com extensão de imagem conhecida
      final imgSrc = RegExp(
        r'''<img\s[^>]*src=["'](https?://[^"']+\.(?:jpg|jpeg|png|webp))["']''',
        caseSensitive: false,
      ).firstMatch(snippet)?.group(1) ?? '';
      if (imgSrc.isNotEmpty &&
          !imgSrc.contains('logo') &&
          !imgSrc.contains('icon')) {
        debugPrint('=== ogImage OK (img): $imgSrc');
        return imgSrc;
      }

      debugPrint('=== ogImage: nenhuma encontrada');
      return '';
    } catch (e) {
      debugPrint('=== ogImage ERRO: $e');
      return '';
    }
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
}