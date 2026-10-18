import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Downloads/download_card.dart';
import 'package:v1_game/Downloads/download_record.dart';
import 'package:v1_game/Downloads/downloads_controller.dart';
import 'package:v1_game/Downloads/downloads_tela.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Downloads/download_progress_bar.dart';
import 'package:v1_game/Downloads/game_preparation.dart';
import 'dart:async';

class ControlledPreparation extends GamePreparation {
  final result = Completer<String?>();
  PreparationTask? task;
  @override
  Future<String?> prepare(
      DownloadRecord record, PreparationTask task, PreparationStatus status,
      {bool allowExisting = true}) async {
    this.task = task;
    status('Extraindo arquivos do jogo…', .42);
    final path = await result.future;
    task.check();
    return path;
  }
}

class TelaController extends DownloadsController {
  TelaController(
      {GamePreparation? preparation, GamePreparation? silentPreparation})
      : super(preparation: preparation, silentPreparation: silentPreparation);
  final registered = <String>[];
  @override
  Future<void> registerInstalledGame(DownloadRecord record, String path) async {
    record.launchPath = path;
    record.installationState = 'ready';
    record.installationStatus = 'Pronto para jogar';
    record.installationError = null;
    registered.add(path);
    notifyListeners();
  }

  final records = List.generate(
      2,
      (i) => DownloadRecord(
          id: '${i + 1}' * 40,
          name: 'Jogo ${i + 1}',
          torrentFiles: ['teste.torrent'],
          sourceName: 'FitGirl Repacks',
          destination: 'Downloads/games torrent downloads/jogo${i + 1}',
          destinationChosen: true,
          acquiredAt: DateTime(2026),
          totalBytes: 100));
  int starts = 0;
  int deletes = 0;

  /// Catálogo de capas do teste: só o que [setInstalledCover] gravou.
  final covers = <String, String>{};
  @override
  Future<bool> hasInstalledCover(String executable) async =>
      covers.containsKey(executable);
  @override
  Future<void> setInstalledCover(String executable, String image) async =>
      covers[executable] = image;
  @override
  List<DownloadRecord> get items => records;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> start(DownloadRecord record) async {
    starts++;
    record.state = DownloadState.downloading;
    notifyListeners();
  }

  @override
  Future<void> pause(DownloadRecord record) async {
    record.state = DownloadState.paused;
    notifyListeners();
  }

  @override
  Future<void> cancel(DownloadRecord record) async {
    record.state = DownloadState.canceled;
    notifyListeners();
  }

  @override
  Future<void> delete(DownloadRecord record,
      {bool deletePayload = false}) async {
    deletes++;
    records.remove(record);
    notifyListeners();
  }
}

void main() {
  for (final source in ['DODI Repacks', 'ElAmigos', 'Outro release', '']) {
    testWidgets('Release "$source" avisa e abre só a pasta', (tester) async {
      final controller = TelaController();
      addTearDown(() async {
        await controller.engine.close();
        controller.dispose();
      });
      final item = controller.records.first
        ..sourceName = source
        ..state = DownloadState.completed
        ..launchPath = 'executavel-salvo.exe';
      String? opened;
      var launched = false;
      await tester.pumpWidget(MaterialApp(
          home: DownloadsTela(
              controller: controller,
              enablePad: false,
              onOpenFolder: (path) async => opened = path,
              onLaunchGame: (_) async => launched = true)));
      await tester.pumpAndSettle();
      // Sem protocolo automático o cartão não oferece Jogar: só Abrir pasta,
      // com o aviso fixo no próprio cartão.
      expect(find.text('Jogar'), findsNothing);
      expect(find.textContaining('ainda não tem protocolo automático'),
          findsOneWidget);
      await tester.tap(find.text('Abrir pasta'));
      await tester.pumpAndSettle();
      expect(opened, item.destination);
      expect(launched, isFalse);
      expect(item.launchPath, 'executavel-salvo.exe');
      expect(find.text('Selecionar executável do jogo'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Barra grossa contém as duas etapas e depois o progresso real',
      (tester) async {
    final item = DownloadRecord(
        id: '1' * 40,
        name: 'Teste',
        torrentFiles: [],
        destination: '',
        acquiredAt: DateTime(2026),
        state: DownloadState.downloading,
        totalBytes: 100);
    Future<void> render() => tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
                width: 280,
                child:
                    DownloadProgressBar(item: item, color: Colors.purple)))));
    await render();
    expect(find.text('Analisando torrent • 05:00'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        isNull);
    expect(tester.getSize(find.byType(LinearProgressIndicator)).height, 52);
    item.analysisElapsed = const Duration(minutes: 5);
    await render();
    expect(find.text('Verificando dados finais • 03:00'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        isNull);
    item.receivedData = true;
    item.downloadedBytes = 25;
    await render();
    expect(find.text('25.0%'), findsOneWidget);
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        .25);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Apenas cartão em foco expande ações; Enter inicia e mantém os demais itens',
      (tester) async {
    final controller = TelaController();
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        home: DownloadsTela(controller: controller, enablePad: false)));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    final second = find.byKey(ValueKey('focus-${controller.records[1].id}'));
    tester.widget<Focus>(second).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    expect(find.text('Iniciar'), findsOneWidget);
    final card = find.ancestor(
        of: find.text('Iniciar'), matching: find.byType(DownloadCard));
    expect(tester.widget<DownloadCard>(card).item.name, 'Jogo 2');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 250));
    expect(controller.starts, 1);
    expect(controller.records.first.state, DownloadState.ready);
    expect(controller.records.last.state, DownloadState.downloading);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Instalar não abre o jogo: o próximo Jogar é que pede a capa',
      (tester) async {
    final preparation = ControlledPreparation();
    final controller = TelaController(preparation: preparation);
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    controller.records.first.state = DownloadState.completed;
    final launched = <String>[];
    await tester.pumpWidget(MaterialApp(
        home: DownloadsTela(
            controller: controller,
            enablePad: false,
            onLaunchGame: (path) async => launched.add(path))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jogar'));
    await tester.pump();
    preparation.result.complete('jogo.exe');
    await tester.pumpAndSettle();
    // Instalou e cadastrou, mas não abriu: o jogador precisa clicar de novo.
    expect(controller.registered, ['jogo.exe']);
    expect(launched, isEmpty);
    expect(find.textContaining('Jogar agora pede a capa'), findsOneWidget);
    expect(find.textContaining('escolher a capa e abrir o jogo'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Jogo com capa própria abre direto, sem passar pelo seletor',
      (tester) async {
    final preparation = ControlledPreparation();
    final controller = TelaController(preparation: preparation);
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    controller.records.first
      ..state = DownloadState.completed
      ..installationState = 'ready'
      ..launchPath = 'jogo.exe';
    controller.covers['jogo.exe'] = 'capa-escolhida.png';
    final launched = <String>[];
    var asked = 0;
    await tester.pumpWidget(MaterialApp(
        home: DownloadsTela(
            controller: controller,
            enablePad: false,
            chooseCover: (_) async {
              asked++;
              return 'outra.png';
            },
            onLaunchGame: (path) async => launched.add(path))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jogar'));
    await tester.pump();
    preparation.result.complete('jogo.exe');
    await tester.pumpAndSettle();
    expect(launched, ['jogo.exe']);
    expect(asked, 0);
    expect(controller.covers['jogo.exe'], 'capa-escolhida.png');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Jogo pronto sem capa só abre depois de escolher a capa',
      (tester) async {
    final preparation = ControlledPreparation();
    final controller = TelaController(preparation: preparation);
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    controller.records.first
      ..state = DownloadState.completed
      ..installationState = 'ready'
      ..launchPath = 'jogo.exe';
    final launched = <String>[];
    String? chosen;
    await tester.pumpWidget(MaterialApp(
        home: DownloadsTela(
            controller: controller,
            enablePad: false,
            chooseCover: (_) async => chosen,
            onLaunchGame: (path) async => launched.add(path))));
    await tester.pumpAndSettle();
    // Jogador desiste do seletor: sem capa, o jogo não abre.
    await tester.tap(find.text('Jogar'));
    await tester.pump();
    preparation.result.complete('jogo.exe');
    await tester.pumpAndSettle();
    expect(launched, isEmpty);
    expect(controller.covers, isEmpty);
    expect(find.textContaining('abre depois de escolher a capa'),
        findsOneWidget);
    // Com a capa escolhida, o Jogar seguinte grava e abre o jogo. O aviso sai
    // da frente e o cartão, agora mais alto, volta para dentro da rolagem.
    chosen = 'capa.png';
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Jogar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jogar'));
    await tester.pumpAndSettle();
    expect(controller.covers['jogo.exe'], 'capa.png');
    expect(launched, ['jogo.exe']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sair da tela depois de Abrir pasta não notifica no desmonte',
      (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('window_manager'), (_) async => null);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('window_manager'), null));
    final controller = TelaController();
    final janela = JanelaCtrl();
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
      janela.dispose();
    });
    controller.records.first.state = DownloadState.completed;
    await tester.pumpWidget(ChangeNotifierProvider<JanelaCtrl>.value(
        value: janela,
        child: MaterialApp(
            home: DownloadsTela(
                controller: controller,
                enablePad: false,
                onOpenFolder: (_) async {}))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Abrir pasta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abrir pasta'));
    await tester.pumpAndSettle();
    // A tela solta a janela para o Explorer, então o desmonte tem o que repor.
    expect(janela.telaPresa, isFalse);
    // Trocar a árvore desmonta a tela dentro do quadro, que é justamente
    // quando o provider não pode ser notificado.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    expect(janela.telaPresa, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Excluir solicita confirmação antes de remover o item',
      (tester) async {
    final controller = TelaController();
    addTearDown(() async {
      await controller.engine.close();
      controller.dispose();
    });
    await tester.pumpWidget(MaterialApp(
        home: DownloadsTela(controller: controller, enablePad: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(controller.deletes, 0);
    expect(find.text('Excluir também o jogo instalado'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir').last);
    await tester.pumpAndSettle();
    expect(controller.deletes, 1);
    expect(controller.records.length, 1);
    expect(tester.takeException(), isNull);
  });
}
