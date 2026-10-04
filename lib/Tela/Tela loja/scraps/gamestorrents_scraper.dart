import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import 'catalogo_scraper.dart';

/// Todos os seletores específicos do site ficam neste arquivo.
class GamesTorrentsSeletores {
  static const cards = 'article.game-card';
  static const titulo = 'h3 a';
  static const imagem = '.card-art img';
  static const genero = '.card-genre';
  static const paginacao = '.pagination a';
  static const filtros = '.genre-option';
  static const total = '.catalog-total';
}

class GamesTorrentsScraper implements CatalogoScraper {
  final http.Client _client;
  GamesTorrentsScraper({http.Client? client})
      : _client = client ?? http.Client();

  @override
  String get nome => 'GamesTorrents';
  @override
  Uri get catalogo =>
      Uri.parse('https://www.gamestorrents.app/pt-br/jogos-pc/');

  bool _paginaPermitida(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == catalogo.host &&
      uri.path == catalogo.path;

  @override
  Future<PaginaCatalogo> carregar(Uri pagina) async {
    if (!_paginaPermitida(pagina)) {
      throw const ErroCatalogo('Endereço de catálogo inválido.');
    }
    final response = await _client.get(pagina, headers: {
      'Accept': 'text/html',
      'Accept-Language': 'pt-BR,pt;q=0.9',
    }).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw ErroCatalogo(
          'O site respondeu com HTTP ${response.statusCode}. Tente novamente.');
    }
    return interpretar(utf8.decode(response.bodyBytes), pagina);
  }

  /// Função independente de rede para validar mudanças no HTML com fixtures.
  PaginaCatalogo interpretar(String conteudo, Uri pagina) {
    final document = html.parse(conteudo);
    final jogos = <JogoCatalogo>[];
    final vistos = <String>{};
    for (final card
        in document.querySelectorAll(GamesTorrentsSeletores.cards)) {
      final titulo = card.querySelector(GamesTorrentsSeletores.titulo);
      if (titulo == null) continue;
      final copia = titulo.clone(true);
      for (final extra in copia.querySelectorAll('.sr-only')) {
        extra.remove();
      }
      final nome = copia.text.trim();
      final href = titulo.attributes['href'];
      if (nome.isEmpty || href == null || href.isEmpty) continue;
      final url = pagina.resolve(href);
      if (url.scheme != 'https' ||
          url.host != catalogo.host ||
          !vistos.add(url.toString())) {
        continue;
      }
      final img = card.querySelector(GamesTorrentsSeletores.imagem);
      final src = img?.attributes['data-media-original'] ??
          img?.attributes['data-src'] ??
          img?.attributes['src'];
      final imagem = src == null || src.isEmpty ? null : pagina.resolve(src);
      jogos.add(JogoCatalogo(
        nome: nome,
        pagina: url,
        imagem: imagem != null && ['https', 'http'].contains(imagem.scheme)
            ? imagem
            : null,
        generos: List.unmodifiable(card
            .querySelectorAll(GamesTorrentsSeletores.genero)
            .map((e) => e.text.trim())
            .where((e) => e.isNotEmpty)
            .toSet()),
      ));
    }
    // Não confundir bloqueio/alteração de layout com um catálogo vazio.
    if (jogos.isEmpty && document.querySelector('.catalog-controls') == null) {
      throw const ErroCatalogo(
          'Não foi possível reconhecer o catálogo. O site pode estar indisponível ou ter alterado sua estrutura.');
    }
    Uri? proxima;
    final atual = int.tryParse(pagina.queryParameters['page'] ?? '1') ?? 1;
    for (final link
        in document.querySelectorAll(GamesTorrentsSeletores.paginacao)) {
      final href = link.attributes['href'];
      if (href == null) continue;
      final url = pagina.resolve(href);
      final numero = int.tryParse(url.queryParameters['page'] ?? '');
      if (_paginaPermitida(url) && numero != null && numero > atual) {
        proxima = url;
        break;
      }
    }
    final generos = <String, String>{};
    for (final filtro
        in document.querySelectorAll(GamesTorrentsSeletores.filtros)) {
      final valor = filtro.querySelector('input')?.attributes['value'];
      final rotulo = filtro.querySelector('span span')?.text.trim();
      if (valor != null && rotulo != null && rotulo.isNotEmpty) {
        generos[valor] = rotulo;
      }
    }
    return PaginaCatalogo(
      jogos: List.unmodifiable(jogos),
      proxima: proxima,
      generos: Map.unmodifiable(generos),
      total:
          document.querySelector(GamesTorrentsSeletores.total)?.text.trim() ??
              '',
    );
  }

  @override
  void dispose() => _client.close();
}
