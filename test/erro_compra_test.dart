import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:v1_game/Tela/Tela%20loja/detalhes_jogo_tela.dart';
import 'package:v1_game/Tela/Tela%20loja/downloads/torrent_download.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/diagnostico_catalogo.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_download_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/jogo_detalhes.dart';

final _pagina = Uri.parse('https://www.gamestorrents.app/pt-br/jogos-pc/x/');
final _versao = VersaoJogo(
    titulo: 'Edição atual',
    fonte: 'FitGirl',
    informacoes: const {'Build': '1'},
    torrent:
        Uri.parse('https://www.gamestorrents.app/pt-br/download/${'a' * 32}/'));

class _FichaComVersao implements DetalhesScraper {
  @override
  Future<JogoDetalhes> carregar(Uri pagina) async =>
      JogoDetalhes(pagina: pagina, nome: 'Jogo', versoes: [_versao]);
  @override
  void dispose() {}
}

class _FichaQueFalha implements DetalhesScraper {
  _FichaQueFalha(this.erro);
  final Object erro;
  @override
  Future<JogoDetalhes> carregar(Uri pagina) async => throw erro;
  @override
  void dispose() {}
}

/// O downloader que normalmente abre o WebView2.
class _DownloaderQueFalha implements TorrentDownloader {
  _DownloaderQueFalha(this.mensagem);
  final String mensagem;
  @override
  void cancelar() {}
  @override
  Future<String> baixar(
          EtapaDownload etapa, void Function(ProgressoTorrent) progresso) =>
      throw StateError(mensagem);
}

Future<void> _abrir(WidgetTester tester, Widget tela) async {
  await tester.binding.setSurfaceSize(const Size(1280, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: tela));
  await tester.pumpAndSettle();
}

void main() {
  group('consulta da etapa de download', () {
    test('DNS bloqueado na compra vira código, não frase genérica', () async {
      final scraper = GamesTorrentsDownloadScraper(client: MockClient((_) async =>
          throw http.ClientException(
              'Failed host lookup: www.gamestorrents.app')));
      addTearDown(scraper.dispose);
      try {
        await scraper.consultar(_versao.torrent);
        fail('esperava falha');
      } on ErroCatalogo catch (erro) {
        expect(erro.diagnostico, isNotNull);
        expect(erro.diagnostico!.falha, FalhaCatalogo.dnsBloqueado);
        expect(erro.diagnostico!.codigo, 'LOJA-DNSBLOQUEADO');
      }
    });

    test('403 na compra aponta Cloudflare, como no catálogo', () async {
      final scraper = GamesTorrentsDownloadScraper(
          client: MockClient((_) async => http.Response('', 403)));
      addTearDown(scraper.dispose);
      try {
        await scraper.consultar(_versao.torrent);
        fail('esperava falha');
      } on ErroCatalogo catch (erro) {
        expect(erro.diagnostico!.falha, FalhaCatalogo.acessoRecusado);
        expect(erro.diagnostico!.status, 403);
      }
    });

    test('a consulta manda User-Agent de navegador', () async {
      Map<String, String>? enviados;
      final scraper = GamesTorrentsDownloadScraper(
          client: MockClient((pedido) async {
        enviados = pedido.headers;
        return http.Response('', 503);
      }));
      addTearDown(scraper.dispose);
      await expectLater(
          scraper.consultar(_versao.torrent), throwsA(isA<ErroCatalogo>()));
      expect(enviados!['User-Agent'], contains('Mozilla/5.0'));
    });

    test('página irreconhecível guarda o tamanho recebido', () async {
      final scraper = GamesTorrentsDownloadScraper(client: MockClient(
          (_) async => http.Response('<html><body>nada</body></html>', 200,
              headers: const {'content-type': 'text/html; charset=utf-8'})));
      addTearDown(scraper.dispose);
      try {
        await scraper.consultar(_versao.torrent);
        fail('esperava falha');
      } on ErroCatalogo catch (erro) {
        expect(erro.diagnostico!.falha, FalhaCatalogo.estruturaMudou);
        expect(erro.diagnostico!.detalhe, contains('data-download-form'));
      }
    });
  });

  group('tela de detalhes', () {
    testWidgets('falha ao carregar a ficha usa o painel do catálogo',
        (tester) async {
      await _abrir(
          tester,
          DetalhesJogoTela(
            jogo: JogoCatalogo(
                nome: 'Jogo', pagina: _pagina, imagem: null, generos: const []),
            scraper: _FichaQueFalha(ErroCatalogo.diagnosticado(
                DiagnosticoCatalogo.doStatus(503, endereco: _pagina))),
          ));

      expect(find.text('O catálogo não carregou'), findsOneWidget);
      expect(find.text('LOJA-SITEINDISPONIVEL'), findsOneWidget);
      expect(find.text('HTTP 503'), findsOneWidget);
      expect(find.text('Copiar detalhes'), findsOneWidget);
      expect(find.textContaining('Verifique sua conexão'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('falha na compra mostra código e botão de copiar',
        (tester) async {
      await _abrir(
          tester,
          DetalhesJogoTela(
            jogo: JogoCatalogo(
                nome: 'Jogo', pagina: _pagina, imagem: null, generos: const []),
            scraper: _FichaComVersao(),
            downloadScraper: _DownloadQueFalha(),
            downloader: _DownloaderQueFalha('não deve chegar aqui'),
          ));

      await tester.tap(find.text('Comprar'));
      await tester.pumpAndSettle();

      expect(find.text('LOJA-DNSBLOQUEADO'), findsOneWidget);
      expect(find.textContaining('rota alternativa'), findsOneWidget);
      expect(find.text('Copiar detalhes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('copiar na compra leva o relatório completo', (tester) async {
      String? copiado;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiado = (call.arguments as Map)['text'] as String;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await _abrir(
          tester,
          DetalhesJogoTela(
            jogo: JogoCatalogo(
                nome: 'Jogo', pagina: _pagina, imagem: null, generos: const []),
            scraper: _FichaComVersao(),
            downloadScraper: _DownloadQueFalha(),
            downloader: _DownloaderQueFalha('não deve chegar aqui'),
          ));

      await tester.tap(find.text('Comprar'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Copiar detalhes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copiar detalhes'));
      await tester.pumpAndSettle();

      expect(copiado, contains('Código: LOJA-DNSBLOQUEADO'));
      expect(copiado, contains('Detalhe:'));
      expect(copiado, contains('gamestorrents.app'));
    });

    testWidgets('erro vindo do WebView2 chega inteiro à tela', (tester) async {
      await _abrir(
          tester,
          DetalhesJogoTela(
            jogo: JogoCatalogo(
                nome: 'Jogo', pagina: _pagina, imagem: null, generos: const []),
            scraper: _FichaComVersao(),
            downloadScraper: _DownloadOk(),
            downloader: _DownloaderQueFalha(
                'O navegador interno não encontrou o endereço do site.\n\n'
                'LOJA-DNSBLOQUEADO\n'
                'WebView2 HOST_NAME_NOT_RESOLVED: ERR_NAME_NOT_RESOLVED'),
          ));

      await tester.tap(find.text('Comprar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('navegador interno'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _DownloadQueFalha implements DownloadScraper {
  @override
  Future<EtapaDownload> consultar(Uri pagina) async =>
      throw ErroCatalogo.diagnosticado(DiagnosticoCatalogo.de(
          http.ClientException('Failed host lookup: ${pagina.host}'),
          endereco: pagina));
  @override
  void dispose() {}
}

class _DownloadOk implements DownloadScraper {
  @override
  Future<EtapaDownload> consultar(Uri pagina) async => EtapaDownload(
      pagina: pagina,
      nomeArquivo: 'jogo.torrent',
      tamanhoArquivo: '50 KiB',
      instrucao: 'Abra no cliente torrent.',
      exigeJavaScript: true,
      podeExigirCaptcha: true);
  @override
  void dispose() {}
}
