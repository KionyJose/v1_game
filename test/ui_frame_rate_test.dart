import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Interface/ui_frame_binding.dart';
import 'package:v1_game/Interface/ui_fps_options.dart';
import 'package:v1_game/Modelos/configs_sistema.dart';
import 'package:v1_game/Widgets/Pops/pop_config.dart';

void main() {
  test('FPS persiste no JSON e configurações antigas iniciam em Livre', () {
    expect(ConfigSistema.fromJson({}).uiFps, 0);
    expect(ConfigSistema.fromJson({'uiFps': 120}).uiFps, 0);
    for (final fps in [0, 30, 60]) {
      final config = ConfigSistema.fromJson({}).copyWith(uiFps: fps);
      expect(ConfigSistema.fromJson(config.toJson()).uiFps, fps);
    }
  });
  for (final displayHz in [120, 165]) {
    for (final fps in [30, 60]) {
      test('$fps FPS não acumula atraso em um monitor de $displayHz Hz', () {
        final budget = UiFrameBudget()..setFps(fps);
        var frames = 0;
        // Emulate a continuously animated UI with presentation on display ticks.
        for (var tick = 0; tick < displayHz * 10; tick++) {
          final now = (tick * 1000000 / displayHz).round();
          if (budget.delayAt(now) != Duration.zero) continue;
          budget.frameBegan(now);
          frames++;
        }
        expect(frames, closeTo(fps * 10, 1));
      });
    }
  }
  test('Retomar após pausa e mudar para Livre remove a espera anterior', () {
    final budget = UiFrameBudget()..setFps(30);
    budget.frameBegan(0);
    expect(budget.delayAt(1).inMicroseconds, greaterThan(33000));
    budget.frameBegan(10000000);
    expect(budget.delayAt(10000001).inMicroseconds, greaterThan(33000));
    budget.setFps(60);
    expect(budget.delayAt(10000001), Duration.zero);
    budget.frameBegan(10000001);
    expect(budget.delayAt(10000002).inMicroseconds, lessThan(17000));
    budget.setFps(0);
    expect(budget.delayAt(10000002), Duration.zero);
  });
  test('Quadros nativos antecipados não acumulam espera para a UI', () {
    final budget = UiFrameBudget()..setFps(30);
    for (var frame = 0; frame < 120; frame++) {
      budget.frameBegan(frame * 8333);
    }
    expect(budget.delayAt(120 * 8333).inMicroseconds, lessThan(34000));
  });
  testWidgets('FPS aceita setas, Enter e clique com apenas um foco',
      (tester) async {
    final node = FocusNode();
    var selected = 0;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StatefulBuilder(builder: (_, update) {
      return UiFpsOptions(
          value: selected,
          focusNode: node,
          onChanged: (value) => update(() => selected = value));
    }))));
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, 30);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, 60);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(selected, 60);
    await tester.tap(find.text('30'));
    expect(selected, 30);
    expect(node.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    node.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Configurações recebem FPS pelo Pad e cancelar mantém a preferência',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pad = Paad(escutar: false, janelaCtrl: JanelaCtrl());
    final original = configSistema;
    configSistema = ConfigSistema.defaults().copyWith(uiFps: 0);
    addTearDown(() {
      configSistema = original;
      pad.dispose();
    });
    await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
        value: pad,
        child: MaterialApp(home: Builder(builder: (context) {
          return Scaffold(
              body: TextButton(
                  onPressed: () => PopConfig.config(context),
                  child: const Text('Abrir configurações')));
        }))));
    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();
    tester
        .widget<UiFpsOptions>(find.byType(UiFpsOptions))
        .focusNode
        .requestFocus();
    await tester.pumpAndSettle();
    for (final (command, expected) in [
      ('DIREITA', 30),
      ('DIREITA', 60),
      ('2', 0)
    ]) {
      pad.click = command;
      pad.attTela();
      await tester.pumpAndSettle();
      expect(tester.widget<UiFpsOptions>(find.byType(UiFpsOptions)).value,
          expected);
      expect(configSistema.uiFps, 0);
    }
    // Exercise the dialog's cancel action without touching real configuration.
    pad.click = '3';
    pad.attTela();
    await tester.pumpAndSettle();
    expect(find.byType(UiFpsOptions), findsNothing);
    expect(configSistema.uiFps, 0);
    expect(pad.comandoAtivo, isTrue);
    // Sair das Configurações religa o mouse, e o religamento tem um atraso
    // próprio no Paad. Sem deixar esse relógio correr, o teste termina com
    // um Timer pendente que não é defeito nenhum.
    // O religamento confirma o estado em dez passos antes de agendar o
    // último atraso, então não adianta um pulo só: é preciso deixar o
    // relógio correr algumas vezes.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
