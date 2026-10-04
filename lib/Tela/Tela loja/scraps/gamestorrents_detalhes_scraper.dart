import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'catalogo_scraper.dart';
import 'jogo_detalhes.dart';

class DetalhesSeletores {
  static const titulo = '.game-heading h1';
  static const capa = '.game-cover img';
  static const generos = '.game-tags .genre-link';
  static const descricao = '[data-description-body]';
  static const imagens = '.gallery-stage .game-gallery-image';
  static const trailers = '.gallery-stage [data-gallery-video]';
  static const versoes = '[data-release-entry]';
  static const torrent = '.release-downloads a';
}

class GamesTorrentsDetalhesScraper implements DetalhesScraper {
  final http.Client _client;
  GamesTorrentsDetalhesScraper({http.Client? client})
      : _client = client ?? http.Client();

  static const host = 'www.gamestorrents.app';

  @override
  Future<JogoDetalhes> carregar(Uri pagina) async {
    if (pagina.scheme != 'https' ||
        pagina.host != host ||
        !RegExp(r'^/pt-br/jogos-pc/[^/]+/$').hasMatch(pagina.path)) {
      throw const ErroCatalogo('Endereço de jogo inválido.');
    }
    final response = await _client.get(pagina,
        headers: {'Accept': 'text/html'}).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw ErroCatalogo(
          'Não foi possível carregar o jogo (HTTP ${response.statusCode}).');
    }
    return interpretar(utf8.decode(response.bodyBytes), pagina);
  }

  Uri? _url(Uri pagina, String? valor) {
    if (valor == null || valor.trim().isEmpty) return null;
    final uri = Uri.tryParse(valor);
    if (uri == null) return null;
    final resultado = pagina.resolveUri(uri);
    return resultado.scheme == 'https' ? resultado : null;
  }

  JogoDetalhes interpretar(String conteudo, Uri pagina) {
    final doc = html.parse(conteudo);
    final nome = doc.querySelector(DetalhesSeletores.titulo)?.text.trim();
    if (nome == null || nome.isEmpty) {
      throw const ErroCatalogo(
          'A página de detalhes mudou ou está indisponível.');
    }
    final capa = doc.querySelector(DetalhesSeletores.capa);
    final imagens = <Uri>{};
    for (final item in doc.querySelectorAll(DetalhesSeletores.imagens)) {
      final imagem = item.querySelector('img');
      final uri = _url(
          pagina,
          item.attributes['href'] ??
              imagem?.attributes['data-media-original'] ??
              imagem?.attributes['src']);
      if (uri != null) imagens.add(uri);
    }
    final trailers = <TrailerJogo>[];
    final ids = <String>{};
    for (final item in doc.querySelectorAll(DetalhesSeletores.trailers)) {
      final id = item.attributes['data-gallery-video'];
      if (id == null ||
          !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ||
          !ids.add(id)) {
        continue;
      }
      final subtitulo = item
          .querySelector('.gallery-video-copy > span:last-child')
          ?.text
          .trim();
      trailers.add(TrailerJogo(
          youtubeId: id,
          titulo: subtitulo ??
              item.attributes['data-video-title'] ??
              'Trailer ${trailers.length + 1}'));
    }
    final versoes = <VersaoJogo>[];
    for (final versao in doc.querySelectorAll(DetalhesSeletores.versoes)) {
      for (final link in versao.querySelectorAll(DetalhesSeletores.torrent)) {
        // Não confundir "Abrir magnet" com o botão de arquivo torrent.
        if (!link.text.toLowerCase().contains('baixar torrent')) continue;
        final uri = _url(pagina, link.attributes['href']);
        if (uri == null ||
            uri.host != host ||
            !uri.path.startsWith('/pt-br/download/')) {
          continue;
        }
        final fatos = <String, String>{};
        for (final fato in versao.querySelectorAll('.release-facts > div')) {
          final chave = fato.querySelector('dt')?.text.trim();
          final valor = fato.querySelector('dd')?.text.trim();
          if (chave != null && valor != null) fatos[chave] = valor;
        }
        versoes.add(VersaoJogo(
            titulo: versao.querySelector('.release-edition')?.text.trim() ??
                versao.querySelector('h3')?.text.trim() ??
                'Versão disponível',
            fonte: versao.querySelector('.release-source-name')?.text.trim() ??
                versao.attributes['data-release-source'] ??
                '',
            informacoes: Map.unmodifiable(fatos),
            torrent: uri));
      }
    }
    final descricao =
        doc.querySelector(DetalhesSeletores.descricao)?.clone(true);
    if (descricao != null) {
      for (final br in descricao.querySelectorAll('br')) {
        br.replaceWith(Text('\n'));
      }
    }
    return JogoDetalhes(
        pagina: pagina,
        nome: nome,
        descricao: descricao?.text.trim() ?? '',
        capa: _url(pagina,
            capa?.attributes['data-media-original'] ?? capa?.attributes['src']),
        generos: List.unmodifiable(doc
            .querySelectorAll(DetalhesSeletores.generos)
            .map((e) => e.text.trim())
            .where((e) => e.isNotEmpty)
            .toSet()),
        imagens: List.unmodifiable(imagens),
        trailers: List.unmodifiable(trailers),
        versoes: List.unmodifiable(versoes));
  }

  @override
  void dispose() => _client.close();
}
