import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';
import 'package:v1_game/Tela/Tela Principal/PrincipalCtrl.dart';

/// `iniciaTela` real sobe media_kit e timers; aqui só interessa qual corpo o
/// controller diz que deve aparecer.
class CtrlDeTeste extends PrincipalCtrl {
  CtrlDeTeste(super.ctx);

  @override
  Future<void> iniciaTela() async {
    focusNodeIcones = [FocusNode()];
    focusNodeAbaGuias = [FocusNode()];
    focusNodeCinema = [];
    focusNodeMusica = [];
    focusNodeLoja = [];
    focusNodeVideos = [];
  }
}

Future<CtrlDeTeste> _montar(WidgetTester tester) async {
  CtrlDeTeste? criado;
  final pad = Paad(escutar: false, janelaCtrl: JanelaCtrl());
  addTearDown(pad.dispose);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<Paad>.value(value: pad),
      ChangeNotifierProvider<JanelaCtrl>(create: (_) => JanelaCtrl()),
    ],
    child: MaterialApp(home: Builder(builder: (context) {
      final ctrl = criado ??= CtrlDeTeste(context)
        ..listIconsInicial = [
          IconInicial([
            'lugar: 1',
            'nome: Jogo',
            'local: jogo.exe',
            'img: ',
            'imgAux: ',
          ])
        ]
        ..stateTela = true;
      return AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) => Scaffold(
            body: Text(ctrl.interfaceChanging
                ? 'passagem'
                : ctrl.transversalMode
                    ? 'transversal'
                    : ctrl.cardGamesGrid
                        ? 'grid'
                        : 'principal')),
      );
    })),
  ));
  await tester.pump();
  return criado!;
}

/// Deixa a troca terminar os seus dois quadros.
///
/// `limparClickPad` ainda agenda um Timer de 450 ms para soltar o Pad; sem
/// drenar, o teste termina com temporizador pendente.
Future<void> _concluir(WidgetTester tester, [Future<void>? troca]) async {
  await tester.pump();
  await tester.pump();
  if (troca != null) await troca;
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  late String tipoOriginal;
  setUp(() => tipoOriginal = configSistema.viewType);
  tearDown(() => configSistema.viewType = tipoOriginal);

  testWidgets('Gravar a configuração não troca o corpo sozinha',
      (tester) async {
    configSistema.viewType = 'list';
    final ctrl = await _montar(tester);
    expect(ctrl.transversalMode, isFalse);

    // É isto que a tela de configurações faz ao salvar, antes de o launcher
    // aplicar a interface. Como `transversalMode` era um getter da config, o
    // corpo transversal entrava já na próxima reconstrução — fora da
    // transição que desmonta o corpo antigo. Era o caminho da tela preta.
    configSistema.viewType = 'transversal';
    await tester.pump();
    await tester.pump();

    expect(ctrl.transversalMode, isFalse,
        reason: 'o corpo só muda quando a interface for aplicada');
    expect(find.text('principal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('O mesmo vale para o modo futurista', (tester) async {
    configSistema.viewType = 'list';
    final ctrl = await _montar(tester);
    expect(ctrl.futuristicMode, isFalse);
    expect(ctrl.compactNavigation, isFalse);

    configSistema.viewType = 'futurista';
    await tester.pump();

    // `compactNavigation` sai de `futuristicMode` e decide navegação, sons e
    // animação de fundo: virar no meio de um quadro é pior ainda.
    expect(ctrl.futuristicMode, isFalse);
    expect(ctrl.compactNavigation, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Na construção o corpo já nasce com o tipo salvo',
      (tester) async {
    configSistema.viewType = 'transversal';
    final ctrl = await _montar(tester);

    // Sem isto o primeiro quadro desenharia o corpo errado e a troca viria
    // depois, fora da transição.
    expect(ctrl.transversalMode, isTrue);
    expect(find.text('transversal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('SELECT alterna o Grid pela transição', () {
    testWidgets('a passagem aparece e a transição não fica presa',
        (tester) async {
      configSistema.viewType = 'list';
      final ctrl = await _montar(tester);
      expect(ctrl.cardGamesGrid, isFalse);

      final troca = ctrl.trocaViewIcones();
      // Antes isto trocava o corpo no mesmo quadro, sem passagem nenhuma.
      expect(ctrl.interfaceChanging, isTrue);

      // O quadro seguinte é a passagem: a árvore antiga sai aqui, sozinha.
      await tester.pump();
      expect(find.text('passagem'), findsOneWidget);

      await _concluir(tester, troca);
      expect(ctrl.interfaceChanging, isFalse,
          reason: 'presa em true é a tela de passagem para sempre');
      expect(ctrl.cardGamesGrid, isTrue);
      expect(find.text('grid'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sair do Grid volta para o tipo salvo', (tester) async {
      configSistema.viewType = 'moderno';
      final ctrl = await _montar(tester);
      expect(ctrl.cardGamesModerno, isTrue);

      await _concluir(tester, ctrl.trocaViewIcones());
      expect(ctrl.cardGamesGrid, isTrue);
      expect(ctrl.cardGamesModerno, isFalse);

      await _concluir(tester, ctrl.trocaViewIcones());
      expect(ctrl.cardGamesGrid, isFalse);
      expect(ctrl.cardGamesModerno, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no Grid o corpo transversal não vale junto', (tester) async {
      configSistema.viewType = 'transversal';
      final ctrl = await _montar(tester);
      expect(ctrl.transversalMode, isTrue);

      // Dois corpos valendo ao mesmo tempo disputariam o mesmo FocusScope.
      await _concluir(tester, ctrl.trocaViewIcones());
      expect(ctrl.cardGamesGrid, isTrue);
      expect(ctrl.transversalMode, isFalse);

      await _concluir(tester, ctrl.trocaViewIcones());
      expect(ctrl.transversalMode, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uma troca em cima da outra não deixa a passagem presa',
        (tester) async {
      configSistema.viewType = 'list';
      final ctrl = await _montar(tester);

      // O segundo SELECT chega no meio da passagem e é recusado; a troca em
      // curso precisa terminar mesmo assim.
      final primeira = ctrl.trocaViewIcones();
      await ctrl.trocaViewIcones();
      await _concluir(tester, primeira);

      expect(ctrl.interfaceChanging, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SELECT durante a passagem é ignorado', (tester) async {
      configSistema.viewType = 'list';
      final ctrl = await _montar(tester);

      final troca = ctrl.trocaViewIcones();
      expect(ctrl.interfaceChanging, isTrue);

      // Entrar de novo no meio da passagem reiniciaria a troca pela metade.
      await ctrl.trocaViewIcones();
      expect(ctrl.cardGamesGrid, isTrue, reason: 'o segundo SELECT não vale');

      await _concluir(tester, troca);
      expect(ctrl.interfaceChanging, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}
