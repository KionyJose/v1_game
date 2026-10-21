import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import 'catalogo_scraper.dart';
import 'cliente_loja.dart';
import 'diagnostico_catalogo.dart';

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
      : _client = client ?? ClienteDaLoja();

  @override
  String get nome => 'GamesTorrents';
  @override
  Uri get catalogo =>
      Uri.parse('https://www.gamestorrents.app/pt-br/jogos-pc/');

  /// A busca do site devolve a mesma grade de `article.game-card` do catálogo,
  /// então [interpretar] serve para as duas sem mudança.
  @override
  Uri busca(String termo) => Uri.https(
      catalogo.host, '/pt-br/buscar/', {'q': termo.trim()});

  @override
  Uri catalogoPorGenero(String genero) => genero.isEmpty
      ? catalogo
      : catalogo.replace(queryParameters: {
          ...catalogo.queryParameters,
          'genre': genero,
        });

  bool _paginaPermitida(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == catalogo.host &&
      (uri.path == catalogo.path || uri.path == busca('').path);

  @override
  Future<PaginaCatalogo> carregar(Uri pagina) async {
    if (!_paginaPermitida(pagina)) {
      throw ErroCatalogo.diagnosticado(DiagnosticoCatalogo.endereco(pagina));
    }
    http.Response response;
    try {
      response = await _client.get(pagina, headers: {
        'Accept': 'text/html',
        'Accept-Language': 'pt-BR,pt;q=0.9',
        // O pacote http manda `Dart/x.y (dart:io)` por padrão, que é
        // assinatura declarada de robô. O Cloudflare do site responde 403 a
        // clientes sem navegador conhecido, e na máquina do cliente isso
        // aparecia como "verifique sua conexão".
        'User-Agent': _userAgent,
      }).timeout(const Duration(seconds: 25));
    } catch (erro) {
      // DNS bloqueado, TLS recusado, tempo esgotado e firewall chegam aqui, e
      // cada um pede uma ação diferente do cliente.
      throw ErroCatalogo.diagnosticado(
          DiagnosticoCatalogo.de(erro, endereco: pagina));
    }
    if (response.statusCode != 200) {
      throw ErroCatalogo.diagnosticado(
          DiagnosticoCatalogo.doStatus(response.statusCode, endereco: pagina));
    }
    String corpo;
    try {
      corpo = utf8.decode(response.bodyBytes);
    } catch (erro) {
      throw ErroCatalogo.diagnosticado(DiagnosticoCatalogo.de(erro,
          endereco: pagina, status: response.statusCode));
    }
    return interpretar(corpo, pagina);
  }

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

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
      // O começo do título ajuda a reconhecer página de bloqueio da operadora
      // ou desafio do Cloudflare entregues no lugar do catálogo.
      final titulo = document.querySelector('title')?.text.trim() ?? '';
      throw ErroCatalogo.diagnosticado(DiagnosticoCatalogo.estrutura(
          'Nenhum "${GamesTorrentsSeletores.cards}" e nenhum ".catalog-controls" '
          'em ${conteudo.length} bytes. Título da página: '
          '"${titulo.length > 80 ? '${titulo.substring(0, 80)}…' : titulo}".',
          endereco: pagina));
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
