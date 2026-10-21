import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'catalogo_scraper.dart';
import 'cliente_loja.dart';
import 'diagnostico_catalogo.dart';
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
      : _client = client ?? ClienteDaLoja();

  @override
  Future<EtapaDownload> consultar(Uri pagina) async {
    if (pagina.scheme != 'https' ||
        pagina.host != 'www.gamestorrents.app' ||
        !RegExp(r'^/pt-br/download/[a-f0-9]{32}/$').hasMatch(pagina.path)) {
      throw ErroCatalogo.diagnosticado(DiagnosticoCatalogo.endereco(pagina));
    }
    http.Response response;
    try {
      response = await _client.get(pagina, headers: const {
        'Accept': 'text/html',
        'Accept-Language': 'pt-BR,pt;q=0.9',
        // Mesmo motivo do catálogo: sem User-Agent de navegador o Cloudflare
        // do site responde 403 a este cliente.
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
            'AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0.0.0 Safari/537.36',
      }).timeout(const Duration(seconds: 25));
    } catch (erro) {
      // A compra falhava aqui com a mesma frase genérica do catálogo antigo.
      throw ErroCatalogo.diagnosticado(
          DiagnosticoCatalogo.de(erro, endereco: pagina));
    }
    if (response.statusCode != 200) {
      throw ErroCatalogo.diagnosticado(
          DiagnosticoCatalogo.doStatus(response.statusCode, endereco: pagina));
    }
    return interpretar(
        utf8.decode(response.bodyBytes, allowMalformed: true), pagina);
  }

  EtapaDownload interpretar(String conteudo, Uri pagina) {
    final doc = html.parse(conteudo);
    final desk = doc.querySelector('[data-download-desk]');
    final config = desk?.attributes['data-download-config'];
    if (config == null || doc.querySelector('[data-download-form]') == null) {
      throw ErroCatalogo.diagnosticado(DiagnosticoCatalogo.estrutura(
          'Sem [data-download-desk] ou [data-download-form] em '
          '${conteudo.length} bytes.',
          endereco: pagina));
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
