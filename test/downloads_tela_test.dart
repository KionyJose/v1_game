import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Downloads/download_card.dart';
import 'package:v1_game/Downloads/download_record.dart';
import 'package:v1_game/Downloads/downloads_controller.dart';
import 'package:v1_game/Downloads/downloads_tela.dart';
import 'package:v1_game/Downloads/download_progress_bar.dart';

class TelaController extends DownloadsController {
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
    expect(find.text('Excluir também os arquivos do jogo'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir').last);
    await tester.pumpAndSettle();
    expect(controller.deletes, 1);
    expect(controller.records.length, 1);
    expect(tester.takeException(), isNull);
  });
}
