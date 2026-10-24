// Fonte de catálogo da aba Cinema: modelos, contrato e a implementação TMDB.
//
// A tela não conhece endereço, parâmetro nem JSON — pede faixas prontas a um
// [CineFonte]. Isso deixa os testes injetarem uma fonte falsa e permite trocar
// o provedor sem reescrever o mosaico.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../System/app_storage.dart';

/// Filme ou série: muda o endpoint no TMDB e o rótulo na ficha.
enum TipoCine { filme, serie }

/// Formato do ladrilho de uma faixa. O catálogo escolhe a forma junto com o
/// conteúdo porque ela faz parte da leitura: capa em pé para lançamento,
/// quadro deitado para destaque, círculo para recorte leve.
enum FormaCine { largo, poster, quadrado, circulo, mosaico }

/// Onde assistir: nome e logo de um serviço de streaming, como o TMDB informa
/// para a região.
@immutable
class ProvedorCine {
  final String nome;
  final String? logo;

  const ProvedorCine({required this.nome, this.logo});

  String? logoUrl({String tamanho = 'w92'}) => TituloCine.imagem(logo, tamanho);
}

/// Um título do catálogo, já traduzido para o que a tela desenha.
@immutable
class TituloCine {
  final int id;
  final TipoCine tipo;
  final String titulo;
  final String sinopse;

  /// Caminhos do TMDB (`/abc.jpg`), não endereços completos: o tamanho da
  /// imagem é escolhido na hora de desenhar, e capa de círculo não precisa do
  /// mesmo peso que o fundo do destaque.
  final String? poster;
  final String? fundo;
  final String? logo;

  final double nota;
  final String ano;
  final List<String> generos;

  /// Id do vídeo no YouTube; nulo enquanto a ficha não foi detalhada.
  final String? trailer;

  final List<ProvedorCine> provedores;

  /// Página de "onde assistir" do próprio TMDB para a região.
  final String? ondeAssistir;

  /// Verdadeiro depois que [CineFonte.detalhar] completou o registro.
  final bool detalhado;

  const TituloCine({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.sinopse = '',
    this.poster,
    this.fundo,
    this.logo,
    this.nota = 0,
    this.ano = '',
    this.generos = const [],
    this.trailer,
    this.provedores = const [],
    this.ondeAssistir,
    this.detalhado = false,
  });

  TituloCine copiaCom({
    String? sinopse,
    String? logo,
    String? fundo,
    List<String>? generos,
    String? trailer,
    List<ProvedorCine>? provedores,
    String? ondeAssistir,
    bool? detalhado,
  }) =>
      TituloCine(
        id: id,
        tipo: tipo,
        titulo: titulo,
        sinopse: sinopse ?? this.sinopse,
        poster: poster,
        fundo: fundo ?? this.fundo,
        logo: logo ?? this.logo,
        nota: nota,
        ano: ano,
        generos: generos ?? this.generos,
        trailer: trailer ?? this.trailer,
        provedores: provedores ?? this.provedores,
        ondeAssistir: ondeAssistir ?? this.ondeAssistir,
        detalhado: detalhado ?? this.detalhado,
      );

  static const _cdn = 'https://image.tmdb.org/t/p/';

  /// Endereço público do CDN de imagens do TMDB — ele não pede chave, então a
  /// arte aparece mesmo em modo demonstração.
  static String? imagem(String? caminho, String tamanho) =>
      caminho == null || caminho.isEmpty ? null : '$_cdn$tamanho$caminho';

  String? posterUrl({String tamanho = 'w500'}) => imagem(poster, tamanho);
  String? fundoUrl({String tamanho = 'w1280'}) => imagem(fundo, tamanho);
  String? logoUrl({String tamanho = 'w500'}) => imagem(logo, tamanho);

  /// Melhor arte disponível para um recorte largo: o fundo, e a capa como
  /// reserva — sem isso um título sem backdrop deixaria buraco na faixa.
  String? arteLarga({String tamanho = 'w780'}) =>
      imagem(fundo ?? poster, tamanho);

  /// Melhor arte para um recorte em pé ou fechado.
  String? arteFechada({String tamanho = 'w500'}) =>
      imagem(poster ?? fundo, tamanho);

  String get rotuloTipo => tipo == TipoCine.filme ? 'Filme' : 'Série';

  String get notaTexto => nota <= 0 ? '—' : nota.toStringAsFixed(1);

  /// Linha curta de apoio, sem repetir o que já está no título.
  String get linhaMeta => [
        if (ano.isNotEmpty) ano,
        rotuloTipo,
        if (generos.isNotEmpty) generos.take(2).join(' · '),
      ].join('  ·  ');
}

/// Uma faixa do mosaico: conteúdo e o formato em que ele é desenhado.
@immutable
class FaixaCine {
  final String titulo;
  final String chamada;
  final FormaCine forma;
  final List<TituloCine> itens;

  const FaixaCine({
    required this.titulo,
    required this.forma,
    required this.itens,
    this.chamada = '',
  });
}

class ErroCine implements Exception {
  final String mensagem;
  final String? detalhe;
  const ErroCine(this.mensagem, [this.detalhe]);
  @override
  String toString() => detalhe == null ? mensagem : '$mensagem ($detalhe)';
}

/// Contrato das fontes de catálogo de cinema.
abstract class CineFonte {
  String get nome;

  /// Falso quando a fonte está servindo conteúdo de demonstração por falta de
  /// configuração — a tela avisa isso em um rodapé discreto.
  bool get configurada;

  Future<List<FaixaCine>> carregar();

  /// Completa o registro: sinopse longa, logo, trailer e onde assistir. A
  /// lista não traz nada disso, e pedir para os cem títulos da grade seria
  /// cem requisições para mostrar uma ficha.
  Future<TituloCine> detalhar(TituloCine titulo);

  void dispose();
}

/// Chave da API do TMDB, procurada em três lugares, nesta ordem:
///
/// 1. `--dart-define=TMDB_KEY=...` na compilação;
/// 2. `v1_tmdb.json` na pasta de dados do usuário — `{"chave": "..."}`;
/// 3. a variável de ambiente `TMDB_API_KEY`.
///
/// Serve tanto a chave v3 (32 caracteres) quanto o token v4 (começa com `ey`).
class ChaveTmdb {
  static const _doBuild = String.fromEnvironment('TMDB_KEY');
  static const arquivoNome = 'v1_tmdb.json';

  static String? _cache;
  static bool _procurada = false;

  /// Caminho mostrado ao usuário quando falta a chave.
  static String get caminhoArquivo {
    try {
      return AppStorage.dataFile(arquivoNome).path;
    } catch (_) {
      return arquivoNome;
    }
  }

  static String? ler() {
    if (_procurada) return _cache;
    _procurada = true;
    _cache = _doBuild.trim().isNotEmpty ? _doBuild.trim() : _doArquivo();
    return _cache;
  }

  static String? _doArquivo() {
    try {
      final arquivo = AppStorage.dataFile(arquivoNome);
      if (arquivo.existsSync()) {
        final dados = jsonDecode(arquivo.readAsStringSync());
        if (dados is Map) {
          final chave =
              (dados['chave'] ?? dados['key'] ?? '').toString().trim();
          if (chave.isNotEmpty) return chave;
        }
      }
    } catch (_) {
      // Arquivo ausente ou ilegível cai no ambiente, abaixo.
    }
    final ambiente = Platform.environment['TMDB_API_KEY']?.trim();
    return ambiente == null || ambiente.isEmpty ? null : ambiente;
  }

  /// Grava a chave na pasta de dados do usuário e esquece o cache.
  static Future<void> salvar(String chave) async {
    final arquivo = AppStorage.dataFile(arquivoNome);
    await arquivo.writeAsString(
        const JsonEncoder.withIndent('  ').convert({'chave': chave.trim()}));
    _procurada = false;
    _cache = null;
  }

  @visibleForTesting
  static void esquecer() {
    _procurada = false;
    _cache = null;
  }
}

/// Catálogo vindo do TMDB, em português do Brasil.
class TmdbFonte implements CineFonte {
  TmdbFonte({String? chave, http.Client? cliente})
      : _chave = chave ?? ChaveTmdb.ler() ?? '',
        _cliente = cliente ?? http.Client();

  final String _chave;
  final http.Client _cliente;

  static const _base = 'api.themoviedb.org';
  static const _idioma = 'pt-BR';
  static const _regiao = 'BR';
  static const _tempoLimite = Duration(seconds: 15);

  /// Nomes de gênero por id, buscados uma vez por sessão: a lista de títulos
  /// só devolve os ids.
  final Map<int, String> _generos = {};

  @override
  String get nome => 'TMDB';

  @override
  bool get configurada => _chave.isNotEmpty;

  /// Token v4 vai no cabeçalho; chave v3 vai na query. Aceitar os dois evita
  /// que a tela falhe por causa de qual botão o usuário clicou no site.
  bool get _ehToken => _chave.startsWith('ey');

  Uri _uri(String caminho, [Map<String, String> parametros = const {}]) =>
      Uri.https(_base, '/3$caminho', {
        'language': _idioma,
        if (!_ehToken) 'api_key': _chave,
        ...parametros,
      });

  Future<Map<String, dynamic>> _json(Uri uri) async {
    late http.Response resposta;
    try {
      resposta = await _cliente.get(uri, headers: {
        'Accept': 'application/json',
        if (_ehToken) 'Authorization': 'Bearer $_chave',
      }).timeout(_tempoLimite);
    } on TimeoutException {
      throw const ErroCine('O TMDB demorou demais para responder.', 'timeout');
    } catch (erro) {
      throw ErroCine('Não foi possível falar com o TMDB.', '$erro');
    }
    if (resposta.statusCode == 401) {
      throw const ErroCine(
          'A chave do TMDB foi recusada.', 'HTTP 401 — chave inválida');
    }
    if (resposta.statusCode != 200) {
      throw ErroCine(
          'O TMDB respondeu com erro.', 'HTTP ${resposta.statusCode}');
    }
    try {
      // `allowMalformed`: um byte solto no meio de uma sinopse não pode
      // derrubar a faixa inteira.
      final dados =
          jsonDecode(utf8.decode(resposta.bodyBytes, allowMalformed: true));
      if (dados is Map<String, dynamic>) return dados;
    } catch (erro) {
      throw ErroCine('A resposta do TMDB veio ilegível.', '$erro');
    }
    throw const ErroCine('A resposta do TMDB veio em formato inesperado.');
  }

  @override
  Future<List<FaixaCine>> carregar() async {
    if (!configurada) {
      throw const ErroCine('Falta a chave do TMDB.', 'sem chave');
    }
    await _carregarGeneros();

    // Cada faixa é um pedido independente: uma que falhe não derruba a tela.
    final pedidos = <_PedidoFaixa>[
      _PedidoFaixa(
        titulo: 'Em alta esta semana',
        chamada: 'o que o mundo está vendo agora',
        forma: FormaCine.largo,
        uri: _uri('/trending/all/week'),
      ),
      _PedidoFaixa(
        titulo: 'Nos cinemas',
        chamada: 'em cartaz no Brasil',
        forma: FormaCine.poster,
        uri: _uri('/movie/now_playing', {'region': _regiao, 'page': '1'}),
        tipo: TipoCine.filme,
      ),
      _PedidoFaixa(
        titulo: 'Séries do momento',
        chamada: 'maratona pronta',
        forma: FormaCine.quadrado,
        uri: _uri('/tv/popular', {'page': '1'}),
        tipo: TipoCine.serie,
      ),
      _PedidoFaixa(
        titulo: 'Leves',
        chamada: 'animação e família',
        forma: FormaCine.circulo,
        uri: _uri('/discover/movie', {
          'with_genres': '16,10751',
          'sort_by': 'popularity.desc',
          'page': '1',
        }),
        tipo: TipoCine.filme,
      ),
      _PedidoFaixa(
        titulo: 'Aclamados',
        chamada: 'nota alta, de ontem e de hoje',
        forma: FormaCine.mosaico,
        uri: _uri('/movie/top_rated', {'page': '1'}),
        tipo: TipoCine.filme,
      ),
      _PedidoFaixa(
        titulo: 'Pra ficar acordado',
        chamada: 'terror e suspense',
        forma: FormaCine.poster,
        uri: _uri('/discover/movie', {
          'with_genres': '27,53',
          'sort_by': 'popularity.desc',
          'page': '1',
        }),
        tipo: TipoCine.filme,
      ),
    ];

    final resultados = await Future.wait(
      pedidos.map((pedido) async {
        try {
          final dados = await _json(pedido.uri);
          final itens = _titulos(dados['results'], pedido.tipo);
          return itens.isEmpty
              ? null
              : FaixaCine(
                  titulo: pedido.titulo,
                  chamada: pedido.chamada,
                  forma: pedido.forma,
                  itens: itens,
                );
        } on ErroCine catch (erro) {
          _ultimoErro = erro;
          return null;
        }
      }),
    );

    final faixas = resultados.whereType<FaixaCine>().toList();
    if (faixas.isEmpty) {
      throw _ultimoErro ?? const ErroCine('O TMDB não devolveu catálogo.');
    }
    return faixas;
  }

  ErroCine? _ultimoErro;

  Future<void> _carregarGeneros() async {
    if (_generos.isNotEmpty) return;
    for (final caminho in ['/genre/movie/list', '/genre/tv/list']) {
      try {
        final dados = await _json(_uri(caminho));
        for (final genero in (dados['genres'] as List? ?? [])) {
          if (genero is Map) {
            final id = (genero['id'] as num?)?.toInt();
            final nome = genero['name']?.toString();
            if (id != null && nome != null) _generos[id] = nome;
          }
        }
      } on ErroCine {
        // Sem a tabela os cartões ficam sem gênero, e só.
      }
    }
  }

  List<TituloCine> _titulos(Object? bruto, TipoCine? tipoPadrao) {
    if (bruto is! List) return const [];
    final titulos = <TituloCine>[];
    for (final item in bruto) {
      if (item is! Map) continue;
      final titulo = _titulo(Map<String, dynamic>.from(item), tipoPadrao);
      if (titulo == null) continue;
      // Sem nenhuma arte o ladrilho vira um retângulo vazio no meio da faixa.
      if (titulo.poster == null && titulo.fundo == null) continue;
      titulos.add(titulo);
    }
    return titulos;
  }

  TituloCine? _titulo(Map<String, dynamic> dados, TipoCine? tipoPadrao) {
    final id = (dados['id'] as num?)?.toInt();
    if (id == null) return null;
    final midia = dados['media_type']?.toString();
    if (midia == 'person') return null;
    final tipo = midia == 'tv'
        ? TipoCine.serie
        : midia == 'movie'
            ? TipoCine.filme
            : tipoPadrao ??
                (dados.containsKey('name') ? TipoCine.serie : TipoCine.filme);
    final nome = (dados['title'] ?? dados['name'] ?? '').toString().trim();
    if (nome.isEmpty) return null;
    final data =
        (dados['release_date'] ?? dados['first_air_date'] ?? '').toString();
    final ids = (dados['genre_ids'] as List? ?? const [])
        .map((e) => (e as num?)?.toInt())
        .whereType<int>();
    return TituloCine(
      id: id,
      tipo: tipo,
      titulo: nome,
      sinopse: (dados['overview'] ?? '').toString().trim(),
      poster: dados['poster_path']?.toString(),
      fundo: dados['backdrop_path']?.toString(),
      nota: ((dados['vote_average'] as num?) ?? 0).toDouble(),
      ano: data.length >= 4 ? data.substring(0, 4) : '',
      generos: ids.map((i) => _generos[i]).whereType<String>().toList(),
    );
  }

  @override
  Future<TituloCine> detalhar(TituloCine titulo) async {
    if (!configurada || titulo.detalhado) return titulo;
    final rota = titulo.tipo == TipoCine.filme ? 'movie' : 'tv';
    final dados = await _json(_uri('/$rota/${titulo.id}', {
      'append_to_response': 'videos,images,watch/providers',
      'include_image_language': 'pt,en,null',
      'include_video_language': 'pt,en,null',
    }));

    final generos = (dados['genres'] as List? ?? const [])
        .whereType<Map>()
        .map((g) => g['name']?.toString())
        .whereType<String>()
        .toList();

    final provedores = <ProvedorCine>[];
    String? ondeAssistir;
    final porRegiao = dados['watch/providers'];
    if (porRegiao is Map && porRegiao['results'] is Map) {
      final br = (porRegiao['results'] as Map)[_regiao];
      if (br is Map) {
        ondeAssistir = br['link']?.toString();
        for (final chave in ['flatrate', 'free', 'ads', 'rent', 'buy']) {
          for (final item in (br[chave] as List? ?? const [])) {
            if (item is! Map) continue;
            final nome = item['provider_name']?.toString();
            if (nome == null || provedores.any((p) => p.nome == nome)) continue;
            provedores.add(
                ProvedorCine(nome: nome, logo: item['logo_path']?.toString()));
          }
        }
      }
    }

    return titulo.copiaCom(
      sinopse: (dados['overview'] ?? titulo.sinopse).toString().trim(),
      logo: _melhorLogo(dados['images']),
      generos: generos.isEmpty ? null : generos,
      trailer: _melhorTrailer(dados['videos']),
      provedores: provedores,
      ondeAssistir: ondeAssistir,
      detalhado: true,
    );
  }

  /// Logo em português se houver, senão em inglês, senão a primeira. O PNG
  /// transparente do título é o que dispensa a caixa de texto no destaque.
  String? _melhorLogo(Object? imagens) {
    if (imagens is! Map) return null;
    final logos = (imagens['logos'] as List? ?? const []).whereType<Map>();
    if (logos.isEmpty) return null;
    for (final idioma in ['pt', 'en']) {
      for (final logo in logos) {
        if (logo['iso_639_1'] == idioma && logo['file_path'] != null) {
          return logo['file_path'].toString();
        }
      }
    }
    return logos.first['file_path']?.toString();
  }

  /// Trailer dublado/legendado na frente do original, e teaser só se não
  /// houver trailer.
  String? _melhorTrailer(Object? videos) {
    if (videos is! Map) return null;
    final lista = (videos['results'] as List? ?? const [])
        .whereType<Map>()
        .where((v) => v['site'] == 'YouTube' && v['key'] != null)
        .toList();
    if (lista.isEmpty) return null;
    int peso(Map v) {
      final tipo = v['type']?.toString();
      final idioma = v['iso_639_1']?.toString();
      return (tipo == 'Trailer'
              ? 0
              : tipo == 'Teaser'
                  ? 2
                  : 4) +
          (idioma == 'pt' ? 0 : 1);
    }

    lista.sort((a, b) => peso(a).compareTo(peso(b)));
    return lista.first['key'].toString();
  }

  @override
  void dispose() => _cliente.close();
}

class _PedidoFaixa {
  final String titulo;
  final String chamada;
  final FormaCine forma;
  final Uri uri;
  final TipoCine? tipo;

  const _PedidoFaixa({
    required this.titulo,
    required this.chamada,
    required this.forma,
    required this.uri,
    this.tipo,
  });
}

/// Catálogo de demonstração, sem rede e sem chave.
///
/// Serve para a tela nascer desenhada enquanto a chave do TMDB não está no
/// lugar: os títulos são reais, as artes não — cada ladrilho cai na arte
/// generativa, que é parte do desenho e não um erro.
class FonteDemoCine implements CineFonte {
  @override
  String get nome => 'Demonstração';

  @override
  bool get configurada => false;

  @override
  Future<TituloCine> detalhar(TituloCine titulo) async =>
      titulo.copiaCom(detalhado: true);

  @override
  void dispose() {}

  @override
  Future<List<FaixaCine>> carregar() async {
    var semente = 700;
    TituloCine t(
      String nome,
      String ano,
      double nota,
      List<String> generos,
      TipoCine tipo,
      String sinopse,
    ) =>
        TituloCine(
          id: semente++,
          tipo: tipo,
          titulo: nome,
          ano: ano,
          nota: nota,
          generos: generos,
          sinopse: sinopse,
        );

    const sinopse =
        'Sinopse completa aparece aqui assim que a chave do TMDB estiver '
        'configurada. Até lá, o catálogo é de demonstração e serve para '
        'conferir o desenho da tela.';

    return [
      FaixaCine(
        titulo: 'Em alta esta semana',
        chamada: 'catálogo de demonstração',
        forma: FormaCine.largo,
        itens: [
          t('Duna: Parte Dois', '2024', 8.2, ['Ficção', 'Aventura'],
              TipoCine.filme, sinopse),
          t('Oppenheimer', '2023', 8.1, ['Drama', 'História'], TipoCine.filme,
              sinopse),
          t('Interestelar', '2014', 8.4, ['Ficção', 'Drama'], TipoCine.filme,
              sinopse),
          t('Blade Runner 2049', '2017', 7.6, ['Ficção'], TipoCine.filme,
              sinopse),
          t('Cidade de Deus', '2002', 8.4, ['Crime', 'Drama'], TipoCine.filme,
              sinopse),
        ],
      ),
      FaixaCine(
        titulo: 'Nos cinemas',
        chamada: 'demonstração',
        forma: FormaCine.poster,
        itens: [
          t('Ainda Estou Aqui', '2024', 8.5, ['Drama'], TipoCine.filme,
              sinopse),
          t('Pobres Criaturas', '2023', 7.8, ['Comédia'], TipoCine.filme,
              sinopse),
          t('Furiosa', '2024', 7.5, ['Ação'], TipoCine.filme, sinopse),
          t('Anatomia de uma Queda', '2023', 7.7, ['Suspense'], TipoCine.filme,
              sinopse),
          t('A Substância', '2024', 7.3, ['Terror'], TipoCine.filme, sinopse),
          t('Perfect Days', '2023', 7.9, ['Drama'], TipoCine.filme, sinopse),
        ],
      ),
      FaixaCine(
        titulo: 'Séries do momento',
        chamada: 'demonstração',
        forma: FormaCine.quadrado,
        itens: [
          t('Fallout', '2024', 8.3, ['Ficção'], TipoCine.serie, sinopse),
          t('Shogun', '2024', 8.6, ['Drama'], TipoCine.serie, sinopse),
          t('Arcane', '2021', 8.8, ['Animação'], TipoCine.serie, sinopse),
          t('Senna', '2024', 8.0, ['Biografia'], TipoCine.serie, sinopse),
          t('Cyberpunk: Edgerunners', '2022', 8.6, ['Animação'], TipoCine.serie,
              sinopse),
        ],
      ),
      FaixaCine(
        titulo: 'Leves',
        chamada: 'animação e família',
        forma: FormaCine.circulo,
        itens: [
          t('Divertida Mente 2', '2024', 7.6, ['Animação'], TipoCine.filme,
              sinopse),
          t('Spider-Man: Através do Aranhaverso', '2023', 8.4, ['Animação'],
              TipoCine.filme, sinopse),
          t('O Menino e a Garça', '2023', 7.5, ['Animação'], TipoCine.filme,
              sinopse),
          t('Robô Selvagem', '2024', 8.3, ['Animação'], TipoCine.filme,
              sinopse),
          t('Elementos', '2023', 7.6, ['Animação'], TipoCine.filme, sinopse),
          t('Viva: A Vida é uma Festa', '2017', 8.2, ['Animação'],
              TipoCine.filme, sinopse),
        ],
      ),
      FaixaCine(
        titulo: 'Aclamados',
        chamada: 'demonstração',
        forma: FormaCine.mosaico,
        itens: [
          t('Cidadão Kane', '1941', 8.0, ['Drama'], TipoCine.filme, sinopse),
          t('O Poderoso Chefão', '1972', 8.7, ['Crime'], TipoCine.filme,
              sinopse),
          t('Parasita', '2019', 8.5, ['Suspense'], TipoCine.filme, sinopse),
          t('Central do Brasil', '1998', 8.0, ['Drama'], TipoCine.filme,
              sinopse),
          t('Seven', '1995', 8.4, ['Crime'], TipoCine.filme, sinopse),
          t('Clube da Luta', '1999', 8.4, ['Drama'], TipoCine.filme, sinopse),
          t('Whiplash', '2014', 8.4, ['Música'], TipoCine.filme, sinopse),
          t('Bacurau', '2019', 7.5, ['Suspense'], TipoCine.filme, sinopse),
        ],
      ),
    ];
  }
}
