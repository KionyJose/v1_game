import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Bando de Dados/db.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Interface/pad_keyboard.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';
import 'package:v1_game/Tela/Tela Principal/PrincipalCtrl.dart';
import 'package:v1_game/Tela/SeletorImagens/SeletorImagens.dart';

class MemoryDB extends DB {
  int writes = 0;
  List<IconInicial> saved = [];
  @override
  Future<void> attDados(List<IconInicial> list) async {
    writes++;
    saved = List.of(list);
  }
}

class RemovalController extends PrincipalCtrl {
  RemovalController(super.ctx);
  @override
  Future<void> iniciaTela() async {
    focusNodeIcones = [];
    focusNodeAbaGuias = [FocusNode()];
    focusNodeCinema = [];
    focusNodeMusica = [];
    focusNodeLoja = [];
    focusNodeVideos = [];
  }
}

void main() {
  late Paad pad;
  setUp(() => pad = Paad(escutar: false, janelaCtrl: JanelaCtrl()));
  tearDown(() => pad.dispose());

  for (final count in [1, 3]) {
    testWidgets('Excluir último card de $count preserva foco e salva uma vez',
        (tester) async {
      late RemovalController ctrl;
      final db = MemoryDB();
      await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
        value: pad,
        child: MaterialApp(home: Builder(builder: (context) {
          ctrl = RemovalController(context)..db = db;
          ctrl.listIconsInicial = List.generate(
              count,
              (i) => IconInicial([
                    'lugar: ${i + 1}',
                    'nome: Jogo $i',
                    'local: jogo$i.exe',
                    'img: ',
                    'imgAux: ',
                  ]));
          ctrl.focusNodeIcones = List.generate(count, (_) => FocusNode());
          ctrl.selectedIndexIcone = count - 1;
          return AnimatedBuilder(
              animation: ctrl,
              builder: (_, child) => Scaffold(
                    body: Column(children: [
                      TextButton(
                          focusNode: ctrl.focusNodeAbaGuias.first,
                          onPressed: () {},
                          child: const Text('Jogos')),
                      for (var i = 0; i < ctrl.listIconsInicial.length; i++)
                        TextButton(
                            focusNode: ctrl.focusNodeIcones[i],
                            onPressed: () {},
                            child: Text(ctrl.listIconsInicial[i].nome)),
                      FilledButton(
                          onPressed: ctrl.excluirCardSelecionado,
                          child: const Text('Excluir card')),
                    ]),
                  ));
        })),
      ));
      await tester.tap(find.text('Excluir card'));
      await tester.pumpAndSettle();
      expect(db.writes, 0);
      pad.interfaceRouter.dispatch('DIREITA');
      await tester.pump();
      pad.interfaceRouter.dispatch('2');
      pad.interfaceRouter.dispatch('2');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      expect(db.writes, 1);
      expect(db.saved.length, count - 1);
      expect(ctrl.listIconsInicial.length, count - 1);
      expect(ctrl.stateTela, isTrue);
      expect(find.text('Excluir card'), findsOneWidget);
      expect(
          count == 1
              ? ctrl.focusNodeAbaGuias.first.hasFocus
              : ctrl.focusNodeIcones.last.hasFocus,
          isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      ctrl.dispose();
    });
  }

  testWidgets(
      'Busca de imagens abre teclado com Pad e preserva consulta inteira',
      (tester) async {
    final queries = <String>[];
    await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
      value: pad,
      child: MaterialApp(
          home: SeletorImagens(
              nome: 'Inicial',
              buscar: (query) async {
                queries.add(query);
                return ['Nenhuma imagem', []];
              })),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    queries.clear();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(find.byType(PadKeyboard), findsOneWidget);
    await tester.enterText(
        find.descendant(
            of: find.byType(PadKeyboard), matching: find.byType(TextField)),
        'Jogo & edição');
    Focus.of(tester.element(find.text('Concluir'))).requestFocus();
    await tester.pump();
    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PadKeyboard), findsNothing);
    expect(queries.first, 'Jogo & edição');
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Jogo & edição');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
