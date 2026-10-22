import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Bando%20de%20Dados/db.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';
import 'package:v1_game/Tela/Tela Principal/PrincipalCtrl.dart';

/// Registra quando o jogo foi aberto e quanto tempo o `openFile` custou.
///
/// O `openFile` real consulta `Win32_Process` pelo PowerShell duas vezes e
/// ainda espera 700 ms por dentro, então na máquina do cliente ele leva
/// segundos. O atraso simulado aqui é o que reproduz o problema original.
class DBEspiao extends DB {
  DBEspiao({this.demora = const Duration(milliseconds: 400)});
  final Duration demora;
  final List<String> abertos = [];
  DateTime? primeiraAberturaEm;

  @override
  openFile(String filePath,
      {String? workingDirectory, bool throwOnError = false}) async {
    abertos.add(filePath);
    primeiraAberturaEm ??= DateTime.now();
    await Future<void>.delayed(demora);
  }

  @override
  Future<void> attDados(List<IconInicial> list) async {}
}

class CtrlDeTeste extends PrincipalCtrl {
  CtrlDeTeste(super.ctx);

  @override
  Future<void> iniciaTela() async {
    focusNodeIcones = [];
    focusNodeAbaGuias = [FocusNode()];
    focusNodeCinema = [];
    focusNodeMusica = [];
    focusNodeLoja = [];
    focusNodeVideos = [];
  }

  /// A animação de reposicionamento do ícone não interessa a estes testes,
  /// mas o tempo que ela consome interessa: continua sendo trabalho feito
  /// entre a animação aparecer e o jogo abrir.
  int moveuIcone = 0;
  @override
  Future<void> moverIcoPosicaoInicial(IconInicial icone) async {
    moveuIcone++;
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
}

/// O Paad da montagem atual, para simular o botão do jogador.
late Paad _pad;

/// O jogador aperta A na folha e volta ao launcher.
///
/// É esta ação que encerra a abertura: a folha não sai sozinha. Depois dela
/// ainda corre o tempo de reativação dos eventos.
Future<void> _fecharFolha(WidgetTester tester, CtrlDeTeste ctrl) async {
  // `click` é campo simples: sem o aviso, o Selector da folha não reconstrói
  // e o botão do jogador não chega até ela.
  _pad.click = '2';
  _pad.attTela();
  await tester.pump();
  await _avancar(tester, const Duration(seconds: 2));
}

Future<CtrlDeTeste> _montar(WidgetTester tester, DBEspiao db,
    {int jogos = 3}) async {
  CtrlDeTeste? criado;
  final pad = Paad(escutar: false, janelaCtrl: JanelaCtrl());
  _pad = pad;
  addTearDown(pad.dispose);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<Paad>.value(value: pad),
      ChangeNotifierProvider<JanelaCtrl>(create: (_) => JanelaCtrl()),
    ],
    child: MaterialApp(home: Builder(builder: (context) {
      // Uma vez só: abrir a folha empurra uma rota, o MaterialApp reconstrói
      // e um controller novo aqui zeraria `stateTela` no meio da abertura.
      final ctrl = criado ??= CtrlDeTeste(context)
        ..db = db
        ..listIconsInicial = List.generate(
            jogos,
            (i) => IconInicial([
                  'lugar: ${i + 1}',
                  'nome: Jogo $i',
                  'local: jogo$i.exe',
                  'img: ',
                  'imgAux: ',
                ]))
        ..focusNodeIcones = List.generate(jogos, (_) => FocusNode())
        ..selectedIndexIcone = 0
        ..stateTela = true;
      return AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) => Scaffold(
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
          ]),
        ),
      );
    })),
  ));
  await tester.pump();
  return criado!;
}

/// Avança o relógio falso em fatias.
///
/// `pumpAndSettle` não serve aqui: a folha de carga tem um indicador que gira
/// sem parar, e o settle nunca chega. O que interessa nestes testes é tempo
/// decorrido, não quadro estável.
Future<void> _avancar(WidgetTester tester, Duration tempo,
    {Duration passo = const Duration(milliseconds: 100)}) async {
  var restante = tempo;
  while (restante > Duration.zero) {
    final fatia = restante < passo ? restante : passo;
    await tester.pump(fatia);
    restante -= fatia;
  }
}

void main() {
  testWidgets('A animação aparece antes de o jogo abrir', (tester) async {
    final db = DBEspiao();
    final ctrl = await _montar(tester, db);

    unawaited(ctrl.btnEntrar());
    await tester.pump();
    await _avancar(tester, const Duration(milliseconds: 500));

    // Meio segundo depois do clique a folha já está na tela e o jogo ainda
    // não subiu. Era exatamente o contrário: o jogo abria primeiro e a
    // animação só aparecia depois.
    expect(find.text('Entrando no game...'), findsOneWidget);
    expect(db.abertos, isEmpty);

    await _avancar(tester, const Duration(seconds: 2));
    expect(db.abertos, ['jogo0.exe']);

    await _fecharFolha(tester, ctrl);
  });

  testWidgets('O jogo abre dois segundos depois da animação', (tester) async {
    final db = DBEspiao();
    final ctrl = await _montar(tester, db);

    unawaited(ctrl.btnEntrar());
    await tester.pump();
    await _avancar(tester, const Duration(milliseconds: 1800));
    expect(db.abertos, isEmpty);
    // A preparação do ícone roda dentro da espera, não depois dela.
    expect(ctrl.moveuIcone, 1);

    await _avancar(tester, const Duration(milliseconds: 500));
    expect(db.abertos.length, 1);

    await _fecharFolha(tester, ctrl);
  });

  testWidgets('A folha espera o jogador, não some sozinha', (tester) async {
    final db = DBEspiao();
    final ctrl = await _montar(tester, db);

    unawaited(ctrl.btnEntrar());
    await tester.pump();
    await _avancar(tester, const Duration(seconds: 10));

    // O jogo já abriu, mas quem volta para o launcher é o jogador: a folha
    // continua na tela e o sistema continua entregue ao jogo.
    expect(db.abertos.length, 1);
    expect(find.text('Entrando no game...'), findsOneWidget);
    expect(ctrl.stateTela, isFalse);
    expect(ctrl.entrandoNoJogo, isTrue);

    await _fecharFolha(tester, ctrl);

    // Só agora o launcher volta a si.
    expect(find.text('Entrando no game...'), findsNothing);
    expect(ctrl.stateTela, isTrue);
    expect(ctrl.gameIniciado, isFalse);
    expect(ctrl.entrandoNoJogo, isFalse);
    expect(ctrl.mouseBloqueado, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cliques repetidos não abrem o jogo mais de uma vez',
      (tester) async {
    final db = DBEspiao(demora: const Duration(seconds: 1));
    final ctrl = await _montar(tester, db);

    // Rajada de cliques, como um duplo-clique de mouse no Transversal.
    for (var i = 0; i < 6; i++) {
      unawaited(ctrl.btnEntrar());
    }
    await tester.pump();
    // A porta fecha no mesmo instante do primeiro clique, sem esperar quadro.
    expect(ctrl.entrandoNoJogo, isTrue);
    expect(ctrl.mouseBloqueado, isTrue);

    await _avancar(tester, const Duration(seconds: 5));
    for (var i = 0; i < 4; i++) {
      unawaited(ctrl.btnEntrar());
    }
    await _avancar(tester, const Duration(seconds: 1));

    expect(db.abertos, ['jogo0.exe']);
    await _fecharFolha(tester, ctrl);
  });

  testWidgets('Cliques durante a abertura não entram na fila', (tester) async {
    final db = DBEspiao(demora: const Duration(milliseconds: 600));
    final ctrl = await _montar(tester, db);

    unawaited(ctrl.btnEntrar());
    await tester.pump();
    // Um clique a cada 200 ms durante toda a sequência.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      unawaited(ctrl.btnEntrar());
    }
    await _avancar(tester, const Duration(seconds: 1));

    expect(db.abertos.length, 1);
    await _fecharFolha(tester, ctrl);
  });

  testWidgets('Depois de voltar, o próximo clique abre outro jogo',
      (tester) async {
    final db = DBEspiao();
    final ctrl = await _montar(tester, db);

    unawaited(ctrl.btnEntrar());
    await _avancar(tester, const Duration(seconds: 3));
    await _fecharFolha(tester, ctrl);
    expect(db.abertos.length, 1);

    ctrl.selectedIndexIcone = 2;
    unawaited(ctrl.btnEntrar());
    await _avancar(tester, const Duration(seconds: 3));
    await _fecharFolha(tester, ctrl);

    expect(db.abertos, ['jogo0.exe', 'jogo2.exe']);
    expect(ctrl.stateTela, isTrue);
  });

  testWidgets('Falha ao abrir devolve o launcher em vez de travar a tela',
      (tester) async {
    final db = _DBQueFalha();
    final ctrl = await _montar(tester, db);

    unawaited(ctrl.btnEntrar());
    await _avancar(tester, const Duration(seconds: 4));

    expect(ctrl.stateTela, isTrue);
    expect(ctrl.gameIniciado, isFalse);
    expect(ctrl.entrandoNoJogo, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Troca de interface durante a abertura não é atropelada',
      (tester) async {
    final db = DBEspiao();
    final ctrl = await _montar(tester, db);

    unawaited(ctrl.btnEntrar());
    await _avancar(tester, const Duration(seconds: 3));
    expect(db.abertos.length, 1);

    // O jogador volta e, logo em seguida, troca o modo da interface.
    ctrl.interfaceChanging = true;
    ctrl.focusScope = ctrl.focusScopeAbaGuias;
    await _fecharFolha(tester, ctrl);

    // A restauração não pode reescrever o foco de quem está trocando de modo.
    // Era a segunda chamada de `_liberarSistema`, 600 ms depois de tudo, que
    // desmontava a árvore recém-montada pela troca.
    expect(ctrl.focusScope, same(ctrl.focusScopeAbaGuias));
    expect(ctrl.stateTela, isTrue, reason: 'os eventos voltam mesmo assim');
    expect(tester.takeException(), isNull);
  });
}
class _DBQueFalha extends DBEspiao {
  @override
  openFile(String filePath,
      {String? workingDirectory, bool throwOnError = false}) async {
    abertos.add(filePath);
    throw const ProcessException('jogo.exe', [], 'executável não encontrado');
  }
}
