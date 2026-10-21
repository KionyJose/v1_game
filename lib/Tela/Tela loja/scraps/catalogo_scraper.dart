import 'diagnostico_catalogo.dart';

/// Contrato comum para fontes de catálogo. A tela não conhece HTML ou seletores.
abstract class CatalogoScraper {
  String get nome;
  Uri get catalogo;

  /// Endereço da busca do próprio site. Sem isso a tela só conseguiria
  /// filtrar as páginas já carregadas, e um jogo que existe no catálogo mas
  /// ainda não foi baixado nunca apareceria.
  Uri busca(String termo);

  /// Catálogo filtrado por um dos [PaginaCatalogo.generos].
  ///
  /// O nome do parâmetro é do site — `genre` na GamesTorrents, `tags` na
  /// Steam — e cada fonte precisa preservar o que o seu endereço base já
  /// carrega. A tela não pode montar isso sozinha: a busca da Steam sem
  /// `infinite=1` devolve a página HTML em vez do JSON.
  Uri catalogoPorGenero(String genero);

  Future<PaginaCatalogo> carregar(Uri pagina);
  void dispose();
}

class JogoCatalogo {
  final String nome;
  final Uri pagina;
  final Uri? imagem;
  final List<String> generos;

  const JogoCatalogo({
    required this.nome,
    required this.pagina,
    required this.imagem,
    required this.generos,
  });

  String get genero =>
      generos.isEmpty ? 'Gênero não informado' : generos.join(' • ');
}

class PaginaCatalogo {
  final List<JogoCatalogo> jogos;
  final Uri? proxima;
  final Map<String, String> generos;
  final String total;

  const PaginaCatalogo({
    required this.jogos,
    this.proxima,
    this.generos = const {},
    this.total = '',
  });
}

class ErroCatalogo implements Exception {
  final String mensagem;

  /// Causa já classificada, quando a fonte conseguiu identificá-la. Carrega o
  /// código e o detalhe técnico que a tela mostra ao cliente e grava no log.
  final DiagnosticoCatalogo? diagnostico;

  const ErroCatalogo(this.mensagem) : diagnostico = null;

  /// Erro cuja mensagem na tela é a do próprio diagnóstico.
  ErroCatalogo.diagnosticado(DiagnosticoCatalogo this.diagnostico)
      : mensagem = diagnostico.mensagem;

  @override
  String toString() => mensagem;
}
