import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:v1_game/Downloads/download_game_launcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Class/pad_interface_router.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Interface/launcher_pad_scope.dart';
import 'package:v1_game/Interface/pad_keyboard.dart';
import 'package:v1_game/Widgets/Pops/pop_mais.dart';
import 'package:v1_game/Tela/Tela loja/scrap_loja.dart';
import 'scrap_loja_test.dart' show FonteTeste;
import 'downloads_tela_test.dart' show TelaController;
import 'package:v1_game/Downloads/download_record.dart';
import 'package:v1_game/Downloads/downloads_tela.dart';
import 'package:v1_game/Downloads/download_destination.dart';
import 'package:v1_game/Tela/Tela loja/detalhes_jogo_tela.dart';
import 'package:v1_game/Tela/Tela loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela loja/scraps/jogo_detalhes.dart';
import 'package:v1_game/Tela/Tela loja/componentes/jogo_card.dart';
import 'package:v1_game/Tela/Tela loja/componentes/galeria_jogo.dart';
import 'package:v1_game/Tela/Tela loja/componentes/game_identity.dart';
import 'package:v1_game/Interface/launcher_header.dart';
import 'detalhes_jogo_tela_test.dart'
    show FonteDetalhesTeste, FonteDownloadTeste, DownloaderTeste, url, versoes;

class FonteNavegacaoTeste extends FonteTeste {
  @override
  Future<PaginaCatalogo> carregar(Uri pagina) async => PaginaCatalogo(
        jogos: List.generate(
            6,
            (index) => JogoCatalogo(
                nome: 'Jogo $index',
                pagina: catalogo.resolve('jogo$index'),
                imagem: null,
                generos: const ['Aventura'])),
        generos: const {'': 'Todos', 'acao': 'Ação', 'aventura': 'Aventura'},
      );
}

class FonteMidiaTeste extends FonteDetalhesTeste {
  @override
  Future<JogoDetalhes> carregar(Uri pagina) async => JogoDetalhes(
        pagina: pagina,
        nome: 'Jogo teste',
        descricao: List.filled(30, 'Descrição legível do jogo.').join('\n'),
        versoes: versoes,
        imagens: [Uri.parse('https://example.com/foto.jpg')],
        trailers: const [
          TrailerJogo(titulo: 'Trailer teste', youtubeId: 'teste')
        ],
      );
}

class DriveController extends TelaController {
  @override
  Future<void> setDownloadDrive(DownloadRecord record, String drive) async {
    record.destination = gameDownloadDirectory(drive, record.name, record.id);
    record.destinationChosen = true;
    notifyListeners();
  }
}

void main() {
  test('Pad roteia somente à interface superior e aceita comandos repetidos',
      () {
    final router = PadInterfaceRouter();
    final received = <String>[];
    final removeRoot =
        router.attach((command) => received.add('root:$command'));
    final removeDialog =
        router.attach((command) => received.add('dialog:$command'));
    router.dispatch('2');
    router.dispatch('2');
    removeDialog();
    router.dispatch('3');
    removeRoot();
    expect(received, ['dialog:2', 'dialog:2', 'root:3']);
    expect(router.dispatch('2'), isFalse);
  });

  late Paad pad;
  setUp(() => pad = Paad(escutar: false, janelaCtrl: JanelaCtrl()));
  tearDown(() => pad.dispose());
  Widget app(Widget home) => ChangeNotifierProvider<Paad>.value(
      value: pad, child: MaterialApp(home: home));

  testWidgets(
      'Pad escolhe disco antes de iniciar, cancela escolha e retoma no mesmo destino',
      (tester) async {
    final controller = DriveController();
    controller.records.first.destinationChosen = false;
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    await tester.pumpWidget(app(DownloadsTela(
        controller: controller, loadDrives: () async => ['C:\\', 'D:\\'])));
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(find.text('Onde baixar o jogo?'), findsOneWidget);
    expect(controller.starts, 0);
    pad.interfaceRouter.dispatch('3');
    await tester.pumpAndSettle();
    expect(controller.starts, 0);
    expect(controller.records.first.destinationChosen, isFalse);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('BAIXO');
    await tester.pumpAndSettle();
    expect(
        Focus.of(tester.element(find.text('Disco D:  •  V1 Jogos'))).hasFocus,
        isTrue);
    pad.interfaceRouter.dispatch('2');
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.starts, 1);
    expect(controller.records.first.destination,
        'D:\\V1 Jogos\\Jogo 1 - 11111111');
    final destination = controller.records.first.destination;
    await controller.pause(controller.records.first);
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Onde baixar o jogo?'), findsNothing);
    expect(controller.starts, 2);
    expect(controller.records.first.destination, destination);
    pad.interfaceRouter.dispatch('2');
    await tester.pump(const Duration(milliseconds: 500));
    final pause = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Pausar').first);
    expect(pause.style!.backgroundColor!.resolve({WidgetState.focused}),
        const Color(0xFF7C4DFF));
    expect(pause.style!.backgroundColor!.resolve({}), Colors.transparent);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Downloads troca cartões verticalmente e mantém a rolagem nas ações horizontais',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = TelaController();
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    await tester.pumpWidget(app(DownloadsTela(controller: controller)));
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('BAIXO');
    await tester.pumpAndSettle();
    final second = tester
        .widget<Focus>(
            find.byKey(ValueKey('focus-${controller.records.last.id}')))
        .focusNode!;
    expect(second.hasPrimaryFocus, isTrue);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    final scroll =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    final position = scroll.pixels;
    pad.interfaceRouter.dispatch('DIREITA');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(scroll.pixels, closeTo(position, 1));
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Focus>(
                find.byKey(ValueKey('focus-${controller.records.first.id}')))
            .focusNode!
            .hasPrimaryFocus,
        isTrue);
    expect(find.text('Iniciar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Jogar aparece ao concluir, usa executável do jogo e aceita A do Pad',
      (tester) async {
    late Directory root;
    late File game;
    await tester.runAsync(() async {
      root = await Directory('test').createTemp('download-play-');
      game = File(p.join(root.path, 'Game.exe'));
      await game.writeAsString('fixture, nunca executada');
      await File(p.join(root.path, 'setup.exe'))
          .writeAsString('instalador, não executar');
      expect(await findDownloadedGames(root.path), [game.path]);
    });
    addTearDown(() => root.delete(recursive: true));
    final controller = TelaController();
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    controller.records.first
      ..destination = root.path
      ..state = DownloadState.completed
      ..downloadedBytes = 100;
    String? launched;
    await tester.pumpWidget(app(DownloadsTela(
        controller: controller,
        onLaunchGame: (path) async => launched = path)));
    await tester.pumpAndSettle();
    expect(find.text('Jogar'), findsOneWidget);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Jogar'))).hasFocus, isTrue);
    pad.interfaceRouter.dispatch('2');
    for (var attempt = 0; attempt < 40 && launched == null; attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)));
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.pumpAndSettle();
    expect(launched, game.path);
    expect(controller.records.first.launchPath, game.path);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seletor de executável funciona pelo Pad e omite instaladores',
      (tester) async {
    late Directory root;
    await tester.runAsync(() async {
      root = await Directory('test').createTemp('download-picker-');
      for (final name in ['Game1.exe', 'Game2.exe', 'setup.exe']) {
        await File(p.join(root.path, name))
            .writeAsString('fixture, nunca executada');
      }
    });
    addTearDown(() => root.delete(recursive: true));
    String? selected;
    await tester.pumpWidget(app(LauncherPadScope(
        child: Scaffold(
            body: Builder(
                builder: (context) => FilledButton(
                      autofocus: true,
                      onPressed: () async => selected =
                          await selectDownloadedGame(context, root.path),
                      child: const Text('Escolher'),
                    ))))));
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    for (var attempt = 0;
        attempt < 20 && find.text('Game1.exe').evaluate().isEmpty;
        attempt++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)));
      await tester.pump(const Duration(milliseconds: 25));
    }
    await tester.pumpAndSettle();
    expect(find.text('Game1.exe'), findsOneWidget);
    expect(find.text('setup.exe'), findsNothing);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(selected, p.join(root.path, 'Game1.exe'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Miniaturas controlam o viewer e A amplia com retorno à seleção',
      (tester) async {
    await tester.pumpWidget(app(LauncherPadScope(
      child: Scaffold(
          body: GaleriaJogo(
        autofocus: true,
        imagens: [
          Uri.parse('https://example.com/1.jpg'),
          Uri.parse('https://example.com/2.jpg')
        ],
      )),
    )));
    await tester.pumpAndSettle();
    final first = tester
        .widget<InkWell>(find.byKey(const ValueKey('game-image-0')))
        .focusNode!;
    final second = tester
        .widget<InkWell>(find.byKey(const ValueKey('game-image-1')))
        .focusNode!;
    expect(first.hasFocus, isTrue);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    pad.interfaceRouter.dispatch('DIREITA');
    await tester.pumpAndSettle();
    expect(second.hasFocus, isTrue);
    expect(find.text('2 / 2'), findsOneWidget);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Fechar imagem'), findsOneWidget);
    pad.interfaceRouter.dispatch('3');
    await tester.pumpAndSettle();
    expect(find.byTooltip('Fechar imagem'), findsNothing);
    expect(second.hasFocus, isTrue);
    pad.interfaceRouter.dispatch('ESQUERDA');
    await tester.pumpAndSettle();
    expect(first.hasFocus, isTrue);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Detalhes integram mídia, versão, compra e descrição sem foco no cabeçalho',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(DetalhesJogoTela(
      jogo: JogoCatalogo(
          nome: 'Jogo teste', pagina: url, imagem: null, generos: const []),
      scraper: FonteMidiaTeste(),
      downloadScraper: FonteDownloadTeste(),
      downloader: DownloaderTeste(),
      onTorrentRecebido: (_, __, ___) async {},
    )));
    await tester.pumpAndSettle();
    final thumbnail = tester
        .widget<InkWell>(find.byKey(const ValueKey('game-image-0')))
        .focusNode!;
    final buy = tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Comprar'))
        .focusNode!;
    expect(tester.getRect(find.byType(GameIdentity)).top,
        closeTo(tester.getRect(find.byType(GaleriaJogo)).top, 1));
    expect(tester.getRect(find.byType(Card).first).top,
        closeTo(tester.getRect(find.byType(GaleriaJogo)).top, 1));
    expect(thumbnail.hasFocus, isTrue);
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(buy.hasFocus, isTrue);
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .focusNode!
            .hasFocus,
        isTrue);
    pad.interfaceRouter.dispatch('BAIXO');
    await tester.pumpAndSettle();
    expect(buy.hasFocus, isTrue);
    pad.interfaceRouter.dispatch('BAIXO');
    await tester.pumpAndSettle();
    expect(thumbnail.hasFocus, isTrue);
    pad.interfaceRouter.dispatch('DIREITA');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<InkWell>(find.byKey(const ValueKey('game-trailer-0')))
            .focusNode!
            .hasFocus,
        isTrue);
    pad.interfaceRouter.dispatch('ESQUERDA');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('BAIXO');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Focus>(find.byKey(const ValueKey('game-description')))
            .focusNode!
            .hasFocus,
        isTrue);
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(thumbnail.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Trailer é ativado no mesmo box e seleção de foto encerra a reprodução',
      (tester) async {
    await tester.pumpWidget(app(LauncherPadScope(
        child: Scaffold(
            body: GaleriaJogo(
      autofocus: true,
      imagens: [Uri.parse('https://example.com/foto.jpg')],
      trailers: const [TrailerJogo(titulo: 'Trailer', youtubeId: 'fixture')],
      trailerBuilder: (_) =>
          const ColoredBox(key: ValueKey('inline-video'), color: Colors.black),
    )))));
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('DIREITA');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inline-video')), findsNothing);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inline-video')), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(
        tester
            .widget<InkWell>(find.byKey(const ValueKey('game-trailer-0')))
            .focusNode!
            .hasFocus,
        isTrue);
    pad.interfaceRouter.dispatch('ESQUERDA');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inline-video')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cabeçalho não recebe foco por teclado ou Pad', (tester) async {
    final content = FocusNode();
    addTearDown(content.dispose);
    await tester.pumpWidget(app(LauncherPadScope(
        child: Scaffold(
      appBar: const LauncherHeader(title: Text('Loja Interna')),
      body: FilledButton(
          focusNode: content,
          autofocus: true,
          onPressed: () {},
          child: const Text('Conteúdo')),
    ))));
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(content.hasFocus, isTrue);
    for (var index = 0; index < 4; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(content.hasFocus, isTrue);
    }
    expect(find.byTooltip('Travar tela'), findsOneWidget);
    expect(find.byTooltip('Fechar aplicativo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Categorias e jogos recebem foco no primeiro item ao entrar',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(ScrapLoja(scraper: FonteNavegacaoTeste())));
    await tester.pumpAndSettle();
    expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        0);
    expect(tester.getSize(find.byType(TextField)).width, closeTo(1100 / 3, 1));
    expect(tester.getCenter(find.text('Loja Interna')).dx, closeTo(550, 1));
    expect(
        tester
            .widget<JogoCard>(find.byType(JogoCard).first)
            .focusNode!
            .hasFocus,
        isTrue);
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Todos'))
            .focusNode!
            .hasFocus,
        isTrue);
    pad.interfaceRouter.dispatch('DIREITA');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Ação'))
            .selected,
        isTrue);
    pad.interfaceRouter.dispatch('BAIXO');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<JogoCard>(find.byType(JogoCard).first)
            .focusNode!
            .hasFocus,
        isTrue);
    pad.interfaceRouter.dispatch('DIREITA');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Todos'))
            .focusNode!
            .hasFocus,
        isTrue);
    expect(find.text('Ver detalhes'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Descrição rola pelo Pad e retorna com fotos e compra visíveis',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(DetalhesJogoTela(
      jogo: JogoCatalogo(
          nome: 'Jogo teste', pagina: url, imagem: null, generos: const []),
      scraper: FonteMidiaTeste(),
      downloadScraper: FonteDownloadTeste(),
      downloader: DownloaderTeste(),
      onTorrentRecebido: (_, __, ___) async {},
    )));
    await tester.pumpAndSettle();
    final trailer = find.byKey(const ValueKey('game-description'));
    tester.widget<Focus>(trailer).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    final scroll =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    final bottom = scroll.pixels;
    expect(bottom, greaterThan(0));
    expect(tester.getRect(trailer).bottom, lessThanOrEqualTo(600));
    final reading = tester
        .state<ScrollableState>(find
            .descendant(of: trailer, matching: find.byType(Scrollable))
            .first)
        .position;
    expect(reading.pixels, 0);
    pad.interfaceRouter.dispatch('BAIXO');
    await tester.pumpAndSettle();
    expect(reading.pixels, greaterThan(0));
    expect(tester.widget<Focus>(trailer).focusNode!.hasFocus, isTrue);
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(reading.pixels, 0);
    expect(tester.widget<Focus>(trailer).focusNode!.hasFocus, isTrue);
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(scroll.pixels, lessThan(bottom));
    expect(
        tester.getRect(find.byType(GaleriaJogo)).top, greaterThanOrEqualTo(76));
    expect(tester.getRect(find.text('1 / 2')).bottom, lessThanOrEqualTo(600));
    Focus.of(tester.element(find.text('Comprar'))).requestFocus();
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('Comprar')).top, greaterThanOrEqualTo(76));
    expect(tester.getRect(find.text('Comprar')).bottom, lessThanOrEqualTo(600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Teclado usa o Paad: letras repetidas, apagar, espaço e concluir',
      (tester) async {
    String? result;
    await tester.pumpWidget(app(LauncherPadScope(
        child: Scaffold(
            body: Builder(
                builder: (context) => FilledButton(
                    autofocus: true,
                    onPressed: () async {
                      result = await abrirTecladoPad(context);
                    },
                    child: const Text('Digitar')))))));
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(find.text('Teclado interno'), findsOneWidget);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '11');
    pad.interfaceRouter.dispatch('1');
    pad.interfaceRouter.dispatch('4');
    pad.interfaceRouter.dispatch('START');
    await tester.pumpAndSettle();
    expect(result, '1 ');
    expect(find.text('Teclado interno'), findsNothing);
    pad.interfaceRouter.dispatch('START');
    await tester.pumpAndSettle();
    expect(find.text('Menu do launcher'), findsOneWidget);
    expect(find.text('Downloads'), findsOneWidget);
    pad.interfaceRouter.dispatch('3');
    await tester.pumpAndSettle();
    expect(find.text('Menu do launcher'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Busca da Loja Interna abre teclado com A e B fecha apenas o diálogo',
      (tester) async {
    await tester.pumpWidget(app(ScrapLoja(scraper: FonteTeste())));
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(find.text('Teclado interno'), findsOneWidget);
    pad.interfaceRouter.dispatch('3');
    await tester.pumpAndSettle();
    expect(find.text('Teclado interno'), findsNothing);
    expect(find.text('Loja Interna'), findsOneWidget);
    expect(find.text('Jogo de aventura'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Menu flutuante anterior oferece Downloads', (tester) async {
    String? result;
    await tester.pumpWidget(app(Scaffold(
        body: Builder(
            builder: (context) => FilledButton(
                onPressed: () async {
                  result = await PopMais.mais(context);
                },
                child: const Text('Start'))))));
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();
    expect(result, 'Downloads');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Downloads usa A e direcional do mesmo Paad para iniciar e pausar',
      (tester) async {
    final controller = TelaController();
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    await tester.pumpWidget(app(DownloadsTela(controller: controller)));
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pump(const Duration(milliseconds: 250));
    expect(controller.starts, 1);
    expect(controller.records.first.state, DownloadState.downloading);
    // Ao desativar Iniciar, o foco retorna ao cartão; A abre a próxima ação válida.
    pad.interfaceRouter.dispatch('2');
    await tester.pump(const Duration(milliseconds: 250));
    pad.interfaceRouter.dispatch('2');
    await tester.pump(const Duration(milliseconds: 250));
    expect(controller.records.first.state, DownloadState.paused);
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(
        FocusManager.instance.primaryFocus,
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Retomar'))
            .focusNode);
    pad.interfaceRouter.dispatch('DIREITA');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pump(const Duration(milliseconds: 250));
    expect(controller.records.first.state, DownloadState.canceled);
    expect(controller.records.last.state, DownloadState.ready);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Detalhes abrem com Comprar em foco e o Pad confirma a compra',
      (tester) async {
    final download = FonteDownloadTeste();
    await tester.pumpWidget(app(DetalhesJogoTela(
      jogo: JogoCatalogo(
          nome: 'Jogo teste', pagina: url, imagem: null, generos: const []),
      scraper: FonteDetalhesTeste(),
      downloadScraper: download,
      downloader: DownloaderTeste(),
      onTorrentRecebido: (_, __, ___) async {},
    )));
    await tester.pumpAndSettle();
    final buy = find.widgetWithText(FilledButton, 'Comprar');
    expect(Focus.of(tester.element(buy)).hasFocus, isTrue);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(download.ultimaPagina, versoes.first.torrent);
    expect(find.text('Arquivo .torrent baixado e confirmado.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pad percorre ações e confirma ou volta da exclusão',
      (tester) async {
    final controller = TelaController();
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    await tester.pumpWidget(app(DownloadsTela(controller: controller)));
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('ESQUERDA');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    pad.interfaceRouter.dispatch('CIMA');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue);
    pad.interfaceRouter.dispatch('3');
    await tester.pumpAndSettle();
    expect(controller.deletes, 0);
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    pad.interfaceRouter.dispatch('DIREITA');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(controller.deletes, 1);
    expect(controller.records.length, 1);
    expect(tester.takeException(), isNull);
  });
}
