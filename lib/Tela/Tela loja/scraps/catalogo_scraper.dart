/// Contrato comum para fontes de catálogo. A tela não conhece HTML ou seletores.
abstract class CatalogoScraper {
  String get nome;
  Uri get catalogo;
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
  const ErroCatalogo(this.mensagem);
  @override
  String toString() => mensagem;
}
