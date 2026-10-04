import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Tela/Tela%20loja/detalhes_jogo_tela.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/jogo_detalhes.dart';
import 'package:v1_game/Tela/Tela%20loja/downloads/torrent_download.dart';

final url = Uri.parse('https://www.gamestorrents.app/pt-br/jogos-pc/teste/');
final versoes = [
  VersaoJogo(
      titulo: 'Edição atual',
      fonte: 'Fonte 1',
      informacoes: const {'Build': '123'},
      torrent: Uri.parse(
          'https://www.gamestorrents.app/pt-br/download/${'a' * 32}/')),
  VersaoJogo(
      titulo: 'Edição anterior',
      fonte: 'Fonte 2',
      informacoes: const {'Build': '122'},
      torrent: Uri.parse(
          'https://www.gamestorrents.app/pt-br/download/${'b' * 32}/')),
];

class FonteDetalhesTeste implements DetalhesScraper {
  bool falhar = false;
  bool disposed = false;
  @override
  Future<JogoDetalhes> carregar(Uri pagina) async {
    if (falhar) throw const ErroCatalogo('Falha nos detalhes');
    return JogoDetalhes(pagina: pagina, nome: 'Jogo teste', versoes: versoes);
  }

  @override
  void dispose() => disposed = true;
}

class FonteDownloadTeste implements DownloadScraper {
  Uri? ultimaPagina;
  bool falhar = false;
  @override
  Future<EtapaDownload> consultar(Uri pagina) async {
    ultimaPagina = pagina;
    if (falhar) throw const ErroCatalogo('Falha no download');
    return EtapaDownload(
        pagina: pagina,
        nomeArquivo: 'teste.torrent',
        tamanhoArquivo: '50 KiB',
        instrucao: 'Abra no cliente torrent.',
        exigeJavaScript: true,
        podeExigirCaptcha: true);
  }

  @override
  void dispose() {}
}

class DownloaderTeste implements TorrentDownloader {
  EtapaDownload? etapa;
  @override
  Future<String> baixar(
      EtapaDownload etapa, void Function(ProgressoTorrent) progresso) async {
    this.etapa = etapa;
    progresso(const ProgressoTorrent('Recebendo arquivo…', fracao: 0.5));
    return r'C:\Downloads\games torrent compra\teste.torrent';
  }

  @override
  void cancelar() {}
}

Widget tela(FonteDetalhesTeste fonte, FonteDownloadTeste download) =>
    MaterialApp(
        home: DetalhesJogoTela(
            jogo: JogoCatalogo(
                nome: 'Jogo teste',
                pagina: url,
                imagem: null,
                generos: const []),
            scraper: fonte,
            downloadScraper: download,
            downloader: DownloaderTeste(),
            onTorrentRecebido: (_, __, ___) async {}));

void main() {
  testWidgets(
      'Detalhes compactos selecionam versão e Comprar consulta etapa correta',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fonte = FonteDetalhesTeste();
    final download = FonteDownloadTeste();
    await tester.pumpWidget(tela(fonte, download));
    await tester.pumpAndSettle();
    expect(find.text('Este jogo não tem imagens cadastradas.'), findsOneWidget);
    expect(
        find.text('Este jogo não tem trailers cadastrados.'), findsOneWidget);
    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edição anterior').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Comprar'));
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    expect(download.ultimaPagina, versoes.last.torrent);
    expect(find.text(r'C:\Downloads\games torrent compra\teste.torrent'),
        findsOneWidget);
    expect(find.text('Arquivo .torrent baixado e confirmado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    download.falhar = true;
    await tester.ensureVisible(find.text('Comprar'));
    await tester.tap(find.text('Comprar'));
    await tester.pumpAndSettle();
    expect(find.text('Falha no download'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Falha nos detalhes permite nova tentativa e clientes são descartados',
      (tester) async {
    final fonte = FonteDetalhesTeste()..falhar = true;
    await tester.pumpWidget(tela(fonte, FonteDownloadTeste()));
    await tester.pumpAndSettle();
    expect(find.text('Falha nos detalhes'), findsOneWidget);
    fonte.falhar = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Imagens'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(fonte.disposed, isTrue);
  });
}
