import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;

import 'catalogo_scraper.dart';
import 'diagnostico_catalogo.dart';
import 'jogo_detalhes.dart';

/// Seletores da linha de resultado da busca da Steam, em um só lugar.
class SteamSeletores {
  static const linha = 'a.search_result_row';
  static const capa = '.search_capsule img';
  static const titulo = 'span.title';
  static const lancamento = '.search_released';
  static const precoFinal = '.discount_final_price';
  static const precoOriginal = '.discount_original_price';
}

/// A loja da Steam exige dois endereços diferentes, e nenhum deles é HTML de
/// página inteira: a busca devolve JSON com um fragmento `results_html`, e a
/// ficha do jogo devolve JSON puro. Por isso o catálogo e os detalhes ficam em
/// classes separadas, cada uma com o seu formato.
///
/// O `cc`/`l` fixam preço em real e textos em português; sem eles a Steam usa
/// o IP para decidir, e o mesmo jogo aparece com moedas diferentes.
class SteamScraper implements CatalogoScraper {
  final http.Client _client;
  SteamScraper({http.Client? client}) : _client = client ?? http.Client();

  static const host = 'store.steampowered.com';
  static const _porPagina = 50;

  /// Filtros de gênero da própria Steam. São ids de tag, não nomes: a busca
  /// aceita `tags=19` e ignora `genre=Ação`. Os rótulos ficam em português
  /// para casar com o resto da tela.
  static const generosSteam = <String, String>{
    '492': 'Indie',
    '19': 'Ação',
    '21': 'Aventura',
    '122': 'RPG',
    '9': 'Estratégia',
    '599': 'Simulação',
    '597': 'Casual',
    '1667': 'Terror',
    '699': 'Corridas',
    '1774': 'Tiro',
    '1625': 'Plataformas',
    '1695': 'Mundo aberto',
    '1662': 'Sobrevivência',
    '1685': 'Co-op',
    '3859': 'Multijogador',
    '1664': 'Quebra-cabeças',
    '113': 'Grátis para jogar',
  };

  @override
  String get nome => 'Steam';

  @override
  Uri get catalogo => Uri.https(host, '/search/results/', const {
        'query': '',
        'start': '0',
        'count': '$_porPagina',
        'infinite': '1',
        'cc': 'br',
        'l': 'portuguese',
      });

  @override
  Uri busca(String termo) => Uri.https(host, '/search/results/', {
        'term': termo.trim(),
        'start': '0',
        'count': '$_porPagina',
        'infinite': '1',
        'cc': 'br',
        'l': 'portuguese',
      });

  /// A Steam filtra por id de tag em `tags`, e os parâmetros do endereço base
  /// precisam continuar: sem `infinite=1` a busca responde HTML, não JSON.
  @override
  Uri catalogoPorGenero(String genero) => catalogo.replace(queryParameters: {
        ...catalogo.queryParameters,
        if (genero.isNotEmpty) 'tags': genero,
      });

  bool _paginaPermitida(Uri uri) =>
      uri.scheme == 'https' && uri.host == host && uri.path == '/search/results/';

  @override
  Future<PaginaCatalogo> carregar(Uri pagina) async {
    if (!_paginaPermitida(pagina)) {
      throw ErroCatalogo.diagnosticado(DiagnosticoCatalogo.endereco(pagina));
    }
    http.Response response;
    try {
      response = await _client.get(pagina, headers: const {
        'Accept': 'application/json',
        'Accept-Language': 'pt-BR,pt;q=0.9',
        // A Steam serve a busca a qualquer cliente, mas o User-Agent padrão do
        // Dart é assinatura declarada de robô; manter o do navegador evita que
        // uma regra de borda derrube o catálogo sem aviso.
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Safari/537.36',
      }).timeout(const Duration(seconds: 25));
    } catch (erro) {
      // Mesma classificação da Loja Interna: DNS, TLS, firewall e tempo
      // esgotado pedem ações diferentes do cliente.
      throw ErroCatalogo.diagnosticado(
          DiagnosticoCatalogo.de(erro, endereco: pagina));
    }
    if (response.statusCode != 200) {
      throw ErroCatalogo.diagnosticado(
          DiagnosticoCatalogo.doStatus(response.statusCode, endereco: pagina));
    }
    // Um byte fora do UTF-8 não deve virar "verifique sua conexão".
    return interpretar(
        utf8.decode(response.bodyBytes, allowMalformed: true), pagina);
  }

  /// Função independente de rede, para validar mudanças com fixtures.
  PaginaCatalogo interpretar(String conteudo, Uri pagina) {
    Object? decoded;
    try {
      decoded = jsonDecode(conteudo);
    } catch (_) {
      throw const ErroCatalogo(
          'A Steam respondeu em um formato inesperado. Tente novamente.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ErroCatalogo('A resposta da Steam não foi reconhecida.');
    }
    final fragmento = decoded['results_html'];
    if (fragmento is! String) {
      throw const ErroCatalogo(
          'A Steam não devolveu a lista de jogos. O formato da busca mudou.');
    }
    final documento = html.parse(fragmento);
    final jogos = <JogoCatalogo>[];
    final vistos = <String>{};
    for (final linha in documento.querySelectorAll(SteamSeletores.linha)) {
      final jogo = _jogo(linha);
      if (jogo == null || !vistos.add(jogo.pagina.toString())) continue;
      jogos.add(jogo);
    }
    // Uma busca sem resultado é legítima; um fragmento sem nenhuma linha e sem
    // a marca de lista vazia é mudança de estrutura, e não deve virar "zero".
    if (jogos.isEmpty && fragmento.trim().isNotEmpty) {
      throw ErroCatalogo.diagnosticado(DiagnosticoCatalogo.estrutura(
          'Nenhum "${SteamSeletores.linha}" em ${fragmento.length} bytes de '
          'results_html.',
          endereco: pagina));
    }
    final total = decoded['total_count'];
    final inicio = int.tryParse(pagina.queryParameters['start'] ?? '0') ?? 0;
    final quantidade =
        int.tryParse(pagina.queryParameters['count'] ?? '') ?? _porPagina;
    final proximoInicio = inicio + quantidade;
    return PaginaCatalogo(
      jogos: List.unmodifiable(jogos),
      proxima: total is int && proximoInicio < total
          ? pagina.replace(queryParameters: {
              ...pagina.queryParameters,
              'start': '$proximoInicio',
            })
          : null,
      generos: generosSteam,
      total: total is int ? '$total jogos' : '',
    );
  }

  JogoCatalogo? _jogo(Element linha) {
    final appid = linha.attributes['data-ds-appid']?.trim();
    final nome = linha.querySelector(SteamSeletores.titulo)?.text.trim();
    if (appid == null || appid.isEmpty || nome == null || nome.isEmpty) {
      return null;
    }
    // O href da busca vem com rastreamento `?snr=`; a ficha é montada a partir
    // do appid para que o scraper de detalhes receba sempre a mesma forma.
    final capa = linha.querySelector(SteamSeletores.capa)?.attributes['src'];
    final imagem = capa == null || capa.trim().isEmpty
        ? null
        : Uri.tryParse(capa.trim());
    // A Steam não expõe o gênero na linha de resultado; o card usa esse campo
    // como legenda, então ele recebe lançamento e preço, que ela expõe.
    final informacoes = <String>[];
    for (final seletor in const [
      SteamSeletores.lancamento,
      SteamSeletores.precoFinal,
      SteamSeletores.precoOriginal,
    ]) {
      final valor = _texto(linha, seletor);
      if (valor != null && !informacoes.contains(valor)) informacoes.add(valor);
    }
    return JogoCatalogo(
      nome: nome,
      pagina: Uri.https(host, '/app/$appid/'),
      imagem: imagem != null && imagem.scheme == 'https' ? imagem : null,
      generos: List.unmodifiable(informacoes),
    );
  }

  static String? _texto(Element linha, String seletor) {
    final valor = linha.querySelector(seletor)?.text.trim();
    return valor == null || valor.isEmpty ? null : valor;
  }

  @override
  void dispose() => _client.close();
}

/// Ficha do jogo pela API pública `appdetails`. Entrega descrição, gêneros,
/// capturas de tela e preço; não há torrent, então a tela de detalhes mostra
/// o painel de abrir na loja em vez do de compra.
class SteamDetalhesScraper implements DetalhesScraper {
  final http.Client _client;
  SteamDetalhesScraper({http.Client? client})
      : _client = client ?? http.Client();

  static final _ficha = RegExp(r'^/app/(\d+)/$');

  @override
  Future<JogoDetalhes> carregar(Uri pagina) async {
    final appid = _ficha.firstMatch(pagina.path)?.group(1);
    if (pagina.scheme != 'https' ||
        pagina.host != SteamScraper.host ||
        appid == null) {
      throw const ErroCatalogo('Endereço de jogo inválido.');
    }
    final endereco = Uri.https(SteamScraper.host, '/api/appdetails', {
      'appids': appid,
      'cc': 'br',
      'l': 'portuguese',
    });
    final response = await _client.get(endereco, headers: const {
      'Accept': 'application/json',
      'Accept-Language': 'pt-BR,pt;q=0.9',
    }).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw ErroCatalogo(
          'Não foi possível carregar o jogo (HTTP ${response.statusCode}).');
    }
    return interpretar(
        utf8.decode(response.bodyBytes, allowMalformed: true), pagina, appid);
  }

  JogoDetalhes interpretar(String conteudo, Uri pagina, String appid) {
    Object? decoded;
    try {
      decoded = jsonDecode(conteudo);
    } catch (_) {
      throw const ErroCatalogo('Os dados da ficha da Steam mudaram.');
    }
    final envelope = decoded is Map<String, dynamic> ? decoded[appid] : null;
    if (envelope is! Map<String, dynamic> || envelope['success'] != true) {
      throw const ErroCatalogo(
          'A Steam não tem uma ficha pública para este jogo.');
    }
    final dados = envelope['data'];
    if (dados is! Map<String, dynamic>) {
      throw const ErroCatalogo('A ficha da Steam veio vazia.');
    }
    final nome = '${dados['name'] ?? ''}'.trim();
    if (nome.isEmpty) {
      throw const ErroCatalogo(
          'A página de detalhes mudou ou está indisponível.');
    }
    final imagens = <Uri>[];
    for (final captura in (dados['screenshots'] as List? ?? const [])) {
      if (captura is! Map) continue;
      final endereco = _https('${captura['path_full'] ?? ''}');
      if (endereco != null) imagens.add(endereco);
    }
    final generos = <String>[];
    for (final genero in (dados['genres'] as List? ?? const [])) {
      if (genero is! Map) continue;
      final rotulo = '${genero['description'] ?? ''}'.trim();
      if (rotulo.isNotEmpty) generos.add(rotulo);
    }
    final preco = dados['is_free'] == true
        ? 'Grátis'
        : '${(dados['price_overview'] as Map?)?['final_formatted'] ?? ''}'.trim();
    return JogoDetalhes(
      pagina: pagina,
      nome: nome,
      descricao: _semHtml('${dados['short_description'] ?? ''}'),
      capa: _https('${dados['header_image'] ?? ''}'),
      generos: List.unmodifiable(generos),
      imagens: List.unmodifiable(imagens),
      // Os vídeos da Steam são mp4 próprios, não ids do YouTube; o player
      // atual só toca YouTube, então a galeria fica apenas com as capturas.
      trailers: const [],
      versoes: const [],
      preco: preco,
      urlLoja: pagina,
    );
  }

  static Uri? _https(String valor) {
    final texto = valor.trim();
    if (texto.isEmpty) return null;
    final uri = Uri.tryParse(texto);
    return uri != null && uri.scheme == 'https' ? uri : null;
  }

  /// A descrição curta da Steam vem com `<br>` e `<strong>` ocasionais.
  static String _semHtml(String valor) {
    final texto = valor.trim();
    if (texto.isEmpty) return '';
    return html.parseFragment(texto).text?.trim() ?? '';
  }

  @override
  void dispose() => _client.close();
}
