import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Tela/games_busca.dart/games_busca_ctrl.dart';

void main() {
  testWidgets(
      'seleção repetida fecha somente a busca e preserva a tela anterior',
      (tester) async {
    final controller = GamesBuscaCtrl();
    BuildContext? dialogContext;
    var results = 0;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return Scaffold(
          body: TextButton(
        child: const Text('Página da biblioteca'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => Builder(
              builder: (pageContext) => Scaffold(
                    body: TextButton(
                        child: const Text('Procurar jogos'),
                        onPressed: () async {
                          final result = await showDialog<dynamic>(
                              context: pageContext,
                              builder: (context) {
                                dialogContext = context;
                                return const Dialog(
                                    child: Text('Resultados da busca'));
                              });
                          if (result != null) results++;
                        }),
                  )),
        )),
      ));
    })));
    await tester.tap(find.text('Página da biblioteca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Procurar jogos'));
    await tester.pumpAndSettle();
    final game = GameEntry(
        name: 'Teste',
        exePath: r'C:\Games\game.exe',
        installDir: r'C:\Games',
        platform: 'Outros');
    controller.pickGame(dialogContext!, game);
    controller.pickGame(dialogContext!, game);
    await tester.pumpAndSettle();
    expect(results, 1);
    expect(find.text('Procurar jogos'), findsOneWidget);
    expect(find.text('Resultados da busca'), findsNothing);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  test(
      'fim de operação após fechar a busca não notifica um controller descartado',
      () {
    final controller = GamesBuscaCtrl();
    controller.dispose();
    expect(() => controller.setQuery('jogo'), returnsNormally);
  });
}
