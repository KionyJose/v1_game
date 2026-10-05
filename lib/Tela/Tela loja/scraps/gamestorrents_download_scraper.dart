import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'catalogo_scraper.dart';
import 'jogo_detalhes.dart';

/// Inspeciona a resposta do botão torrent sem tratar HTML como arquivo .torrent.
///
/// Fluxo observado no JavaScript público do site em 03/10/2026:
/// GET /pt-br/download/<id>/ entrega o formulário e data-download-config.
/// No navegador, POST action=prepare retorna challenge, difficulty e needs_captcha.
/// O script do próprio site executa sua verificação e solicita hCaptcha quando
/// necessário. POST action=download envia challenge, nonce e h-captcha-response.
/// Somente então a resposta application/x-bittorrent é salva como .torrent.
/// Não existe um link estático para o arquivo na página examinada.
/// Este adaptador lê metadados; EmbeddedTorrentDownloader dispara o formulário
/// no WebView2 interno, salva em Downloads/games torrent compra e acompanha
/// a conclusão. A verificação hCaptcha permanece com o usuário.
class GamesTorrentsDownloadScraper implements DownloadScraper {
  final http.Client _client;
  GamesTorrentsDownloadScraper({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<EtapaDownload> consultar(Uri pagina) async {
    if (pagina.scheme != 'https' ||
        pagina.host != 'www.gamestorrents.app' ||
        !RegExp(r'^/pt-br/download/[a-f0-9]{32}/$').hasMatch(pagina.path)) {
      throw const ErroCatalogo('Endereço de download inválido.');
    }
    final response = await _client.get(pagina,
        headers: {'Accept': 'text/html'}).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw ErroCatalogo(
          'A etapa de download respondeu com HTTP ${response.statusCode}.');
    }
    return interpretar(utf8.decode(response.bodyBytes), pagina);
  }

  EtapaDownload interpretar(String conteudo, Uri pagina) {
    final doc = html.parse(conteudo);
    final desk = doc.querySelector('[data-download-desk]');
    final config = desk?.attributes['data-download-config'];
    if (config == null || doc.querySelector('[data-download-form]') == null) {
      throw const ErroCatalogo(
          'Não foi possível reconhecer a etapa de download do site.');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(config);
    } catch (_) {
      throw const ErroCatalogo('Os dados da etapa de download mudaram.');
    }
    if (decoded is! Map<String, dynamic> || decoded['kind'] != 'torrent') {
      throw const ErroCatalogo(
          'A resposta não corresponde a um arquivo torrent.');
    }
    return EtapaDownload(
      pagina: pagina,
      nomeArquivo: decoded['filename'] is String
          ? decoded['filename'] as String
          : 'download.torrent',
      tamanhoArquivo:
          doc.querySelector('.download-file small')?.text.trim() ?? '',
      instrucao: doc.querySelector('.download-instruction')?.text.trim() ?? '',
      exigeJavaScript: doc.querySelector('noscript') != null,
      podeExigirCaptcha: doc.querySelector('[data-captcha-area]') != null,
    );
  }

  @override
  void dispose() => _client.close();
}
