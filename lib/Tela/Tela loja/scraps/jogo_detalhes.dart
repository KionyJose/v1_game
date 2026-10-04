class TrailerJogo {
  final String titulo;
  final String youtubeId;
  const TrailerJogo({required this.titulo, required this.youtubeId});
  Uri get url => Uri.https('www.youtube.com', '/watch', {'v': youtubeId});
  Uri get miniatura => Uri.https('i.ytimg.com', '/vi/$youtubeId/hqdefault.jpg');
}

class VersaoJogo {
  final String titulo;
  final String fonte;
  final Map<String, String> informacoes;
  final Uri torrent;
  const VersaoJogo(
      {required this.titulo,
      required this.fonte,
      required this.informacoes,
      required this.torrent});
}

class JogoDetalhes {
  final Uri pagina;
  final String nome;
  final String descricao;
  final Uri? capa;
  final List<String> generos;
  final List<Uri> imagens;
  final List<TrailerJogo> trailers;
  final List<VersaoJogo> versoes;
  const JogoDetalhes(
      {required this.pagina,
      required this.nome,
      this.descricao = '',
      this.capa,
      this.generos = const [],
      this.imagens = const [],
      this.trailers = const [],
      this.versoes = const []});
}

abstract class DetalhesScraper {
  Future<JogoDetalhes> carregar(Uri pagina);
  void dispose();
}

/// Resposta HTML do clique em "Baixar torrent", anterior à liberação do arquivo.
class EtapaDownload {
  final Uri pagina;
  final String nomeArquivo;
  final String tamanhoArquivo;
  final String instrucao;
  final bool exigeJavaScript;
  final bool podeExigirCaptcha;
  const EtapaDownload(
      {required this.pagina,
      required this.nomeArquivo,
      required this.tamanhoArquivo,
      required this.instrucao,
      required this.exigeJavaScript,
      required this.podeExigirCaptcha});
}

abstract class DownloadScraper {
  Future<EtapaDownload> consultar(Uri pagina);
  void dispose();
}
