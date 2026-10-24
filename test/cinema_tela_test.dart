import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:v1_game/Modelos/MediaCanal.dart';
import 'package:v1_game/Tela/Cinema/body_cinema.dart';
import 'package:v1_game/Tela/Cinema/cinema_catalogo.dart';
import 'package:v1_game/Tela/Cinema/cinema_efeitos.dart';
import 'package:v1_game/Tela/Cinema/cinema_ficha.dart';
import 'package:v1_game/Tela/Cinema/cinema_ladrilho.dart';
import 'package:v1_game/Tela/Cinema/cinema_trailer.dart';
import 'package:v1_game/Tela/Cinema/cinema_trilho_canais.dart';
import 'package:v1_game/Tela/Cinema/tmdb_cine.dart';
import 'package:v1_game/Tela/Tela Principal/PrincipalCtrl.dart';

/// Controlador sem arranque: o de verdade abre players, lê o banco e sobe a
/// biblioteca de jogos — nada disso tem a ver com a aba de cinema.
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
}

TituloCine _titulo(int id, String nome) => TituloCine(
      id: id,
      tipo: TipoCine.filme,
      titulo: nome,
      sinopse: 'Sinopse de $nome.',
      nota: 7.5,
      ano: '2024',
    );

/// Fonte sem rede e sem imagem: a arte de reserva evita baixar byte nenhum
/// durante o teste de widget.
class FonteFalsa implements CineFonte {
  /// [trailer] nasce nulo: com um id de vídeo, o ciclo do cartão chegaria a
  /// abrir um player de verdade no meio do teste, e o teste iria à rede.
  FonteFalsa({this.erro, this.trailer, this.provedores = const []});

  final Object? erro;
  final String? trailer;
  final List<ProvedorCine> provedores;
  int detalhes = 0;
  int cargas = 0;
  bool fechada = false;

  @override
  String get nome => 'Falsa';

  @override
  bool get configurada => true;

  @override
  Future<List<FaixaCine>> carregar() async {
    cargas++;
    if (erro != null) throw erro!;
    return [
      FaixaCine(
        titulo: 'Em alta',
        forma: FormaCine.largo,
        itens: [_titulo(1, 'Um'), _titulo(2, 'Dois'), _titulo(3, 'Três')],
      ),
      FaixaCine(
        titulo: 'Cartazes',
        forma: FormaCine.poster,
        itens: [_titulo(4, 'Quatro'), _titulo(5, 'Cinco')],
      ),
      FaixaCine(
        titulo: 'Séries',
        forma: FormaCine.quadrado,
        itens: [_titulo(6, 'Seis'), _titulo(7, 'Sete'), _titulo(8, 'Oito')],
      ),
      FaixaCine(
        titulo: 'Leves',
        forma: FormaCine.circulo,
        itens: [_titulo(9, 'Nove'), _titulo(10, 'Dez')],
      ),
      FaixaCine(
        titulo: 'Aclamados',
        forma: FormaCine.mosaico,
        itens: [
          _titulo(11, 'Onze'),
          _titulo(12, 'Doze'),
          _titulo(13, 'Treze'),
          _titulo(14, 'Catorze'),
        ],
      ),
    ];
  }

  @override
  Future<TituloCine> detalhar(TituloCine titulo) async {
    detalhes++;
    return titulo.copiaCom(
      detalhado: true,
      trailer: trailer,
      ondeAssistir: 'https://exemplo/assistir',
      provedores: provedores,
    );
  }

  @override
  void dispose() => fechada = true;
}

class FonteMosaicoPad extends FonteFalsa {
  @override
  Future<List<FaixaCine>> carregar() async => [
        ...await super.carregar(),
        FaixaCine(
            titulo: 'Depois de Aclamados',
            forma: FormaCine.poster,
            itens: [
              _titulo(15, 'Quinze'),
              _titulo(16, 'Dezesseis'),
              _titulo(17, 'Dezessete')
            ]),
      ];
}

class FonteSemOndeAssistir extends FonteFalsa {
  FonteSemOndeAssistir(this.titulo);
  final TituloCine titulo;

  @override
  Future<List<FaixaCine>> carregar() async => [
        FaixaCine(
            titulo: 'Nos cinemas', forma: FormaCine.poster, itens: [titulo]),
      ];

  @override
  Future<TituloCine> detalhar(TituloCine titulo) async =>
      titulo.copiaCom(detalhado: true);
}

Future<BodyCinemaState> _montarTela(
  WidgetTester tester, {
  required CinemaCatalogo catalogo,
  List<MediaCanal> canais = const [],
  Size janela = const Size(1600, 1000),
  List<String>? abertos,
  PageController? paginas,
}) async {
  late CtrlDeTeste ctrl;
  // Uma janela de launcher, e não o telefonzinho padrão do teste: a segunda
  // faixa precisa caber na tela para ser construída.
  tester.view.physicalSize = janela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      ctrl = CtrlDeTeste(context);
      ctrl.selectedIndexAbaGuias = 1; // aba de cinema à mostra
      ctrl.listCinema = canais;
      ctrl.focusNodeCinema = List.generate(canais.length, (_) => FocusNode());
      return Scaffold(
        body: AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) {
            final cinema = BodyCinema(
              ctrl: ctrl,
              catalogo: catalogo,
              sons: false,
              abrirUrl: (url, _) async => abertos?.add(url),
            );
            return paginas == null
                ? cinema
                : PageView(
                    controller: paginas,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      const Text('Jogos'),
                      cinema,
                      const Text('Música')
                    ],
                  );
          },
        ),
      );
    }),
  ));
  await tester.pump(); // carga pedida no pós-quadro
  await tester.pump();
  return tester.state<BodyCinemaState>(find.byType(BodyCinema));
}

/// Deixa os temporizadores de entrada, virada e detalhe dispararem antes do
/// fim do teste. `pumpAndSettle` não serve: o brilho do item em foco é uma
/// animação em laço e nunca assenta.
/// Leva o foco para a faixa de cartazes.
///
/// Na faixa de destaque o primeiro A toca o trailer no topo, e não abre a
/// ficha; quem testa a ficha começa de uma faixa comum.
Future<void> _irParaOsCartazes(
    WidgetTester tester, BodyCinemaState tela) async {
  tela.comando('BAIXO');
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _descansar(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  for (final tipo in TipoCine.values) {
    testWidgets(
        'Google pesquisa o título sem provedores por clique e Pad: $tipo',
        (tester) async {
      final nome = tipo == TipoCine.filme ? "Don't Move" : 'Mistério & Ação';
      final titulo = TituloCine(id: 42, tipo: tipo, titulo: nome);
      final catalogo = CinemaCatalogo(fonte: FonteSemOndeAssistir(titulo));
      final abertos = <String>[];
      final tela =
          await _montarTela(tester, catalogo: catalogo, abertos: abertos);
      tela.comando('2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Google'), findsOneWidget);
      expect(tela.acaoDaFicha, AcaoFicha.ondeAssistir);
      await tester.tap(find.byKey(const ValueKey('ficha-google')));
      await tester.pump();
      tela.comando('2');
      await tester.pump();
      expect(abertos, hasLength(2));
      final termo = '$nome ${tipo == TipoCine.filme ? 'filme' : 'série'}';
      for (final endereco in abertos) {
        final uri = Uri.parse(endereco);
        expect(uri.scheme, 'https');
        expect(uri.host, 'www.google.com');
        expect(uri.path, '/search');
        expect(uri.queryParameters, {'q': termo});
      }
      await tester.pumpWidget(const SizedBox.shrink());
      catalogo.dispose();
    });
  }

  test('cartazes e mosaico crescem 20%, preservando proporções e empilhamento',
      () {
    expect(MedidaCine.poster.width, closeTo(206 * 1.2, .0001));
    expect(MedidaCine.poster.height, closeTo(309 * 1.2, .0001));
    final blocos = MedidaCine.geometriaMosaico(4);
    expect(blocos[0].width, closeTo(372 * 1.2, .0001));
    expect(blocos[0].height, closeTo(300 * 1.2, .0001));
    expect(blocos[1].width, closeTo(208 * 1.2, .0001));
    expect(blocos[1].height, closeTo(144 * 1.2, .0001));
    expect(blocos[2].bottom, closeTo(blocos[0].bottom, .0001));
    expect(blocos[3].height, closeTo(300 * 1.2, .0001));
    expect(LadrilhoCine.podeVirar(FormaCine.mosaico, blocos[0].size), isFalse);
    expect(LadrilhoCine.podeVirar(FormaCine.mosaico, blocos[1].size), isTrue);
    expect(PreviaCine.tamanhoTrailer.height, MedidaCine.poster.height);
    expect(PreviaCine.tamanhoTrailer.aspectRatio, closeTo(16 / 9, .0001));
    expect(MedidaCine.largo, const Size(420, 236));
    expect(MedidaCine.quadrado, 232);
    expect(MedidaCine.circulo, 150);
  });

  testWidgets(
      'serviços rolam apenas a lista, sem revelar Jogos ou mover as abas',
      (tester) async {
    final catalogo = CinemaCatalogo(
        fonte: FonteFalsa(
            provedores:
                List.generate(15, (i) => ProvedorCine(nome: 'Serviço $i'))));
    final paginas = PageController(initialPage: 1);
    final tela = await _montarTela(tester,
        catalogo: catalogo, paginas: paginas, janela: const Size(1024, 700));
    await _irParaOsCartazes(tester, tela);
    tela.comando('2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tela.zonaDaFicha, ZonaFicha.provedores);
    for (final direcao in ['DIREITA', 'ESQUERDA']) {
      for (var i = 0; i < 14; i++) {
        tela.comando(direcao);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(paginas.page, closeTo(1, .00001));
        expect(tela.widget.ctrl.selectedIndexAbaGuias, 1);
      }
    }
    expect(tela.provedorSelecionado, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    paginas.dispose();
    catalogo.dispose();
  });

  test('gatilhos de Xbox e PlayStation reconhecem intensidade e soltura', () {
    for (final comando in ['R2', 'RT', 'RT-255', 'R2-1', 'RT-0.8']) {
      expect(VolumeTrailerCine.passoDoGatilho(comando), 1);
    }
    for (final comando in ['L2', 'LT', 'LT-200', 'L2-0.5']) {
      expect(VolumeTrailerCine.passoDoGatilho(comando), -1);
    }
    for (final comando in ['RT-0', 'LT-20', 'L2-0.05']) {
      expect(VolumeTrailerCine.passoDoGatilho(comando), 0);
    }
    for (final comando in ['RB', 'LB', 'DIREITA', 'RT-invalido']) {
      expect(VolumeTrailerCine.passoDoGatilho(comando), isNull);
    }
  });

  testWidgets('L2/R2 controlam o som do destaque, slide e ficha',
      (tester) async {
    final catalogo = CinemaCatalogo(fonte: FonteFalsa(trailer: 'abc123'));
    final tela = await _montarTela(tester, catalogo: catalogo);
    await tester.pump(const Duration(milliseconds: 600));
    final volume = tester
        .widget<EscopoVolumeTrailer>(find.byType(EscopoVolumeTrailer))
        .notifier!;
    expect(volume.value, 100);
    expect(tela.comando('LT-0'), isTrue);
    expect(volume.value, 100);
    expect(tela.comando('LT-200'), isTrue);
    expect(volume.value, 95);
    // Eventos analógicos sucessivos não fazem o volume disparar.
    tela.comando('LT-255');
    expect(volume.value, 95);
    expect(tela.comando('R2'), isTrue);
    expect(volume.value, 100);
    for (final player
        in tester.widgetList<TrailerCine>(find.byType(TrailerCine))) {
      expect(player.mudo, isFalse);
    }
    await _irParaOsCartazes(tester, tela);
    await tester.pump(BodyCinemaState.ociosidade);
    await tester.pump(ViradaCine.duracao);
    await tester.pump();
    await tester.pump(PreviaCine.duracao);
    await tester.pump();
    expect(tela.etapaDoCartao, EtapaCartao.aberto);
    expect(tela.comando('L2'), isTrue);
    expect(volume.value, 95);
    for (final player
        in tester.widgetList<TrailerCine>(find.byType(TrailerCine))) {
      expect(player.mudo, isFalse);
    }
    tela.comando('2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    tela.comando('2'); // play da ficha
    await tester.pump();
    expect(tela.zonaDaFicha, ZonaFicha.player);
    expect(tela.comando('RT-200'), isTrue);
    expect(volume.value, 100);
    tela.comando('3'); // texto volta, trailer continua
    await tester.pump();
    expect(tela.comando('L2'), isTrue);
    expect(volume.value, 95);
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 120));
      tela.comando('LT-255');
    }
    expect(volume.value, 0);
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 120));
      tela.comando('RT-255');
    }
    expect(volume.value, 100);
    await tester.pumpWidget(const SizedBox.shrink());
    catalogo.dispose();
  });

  for (final direcao in ['ESQUERDA', 'DIREITA']) {
    testWidgets('primeiro $direcao recolhe os slides antes de navegar',
        (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester, catalogo: catalogo);
      await _irParaOsCartazes(tester, tela);
      if (direcao == 'ESQUERDA') tela.comando('DIREITA');
      await tester.pump();
      final item = tela.itemSelecionado;
      await tester.pump(BodyCinemaState.ociosidade);
      await tester.pump(ViradaCine.duracao);
      await tester.pump();
      await tester.pump(PreviaCine.duracao);
      await tester.pump();
      final previa = find.byWidgetPredicate((w) => w is PreviaCine && w.aberta);
      expect(previa, findsOneWidget);
      tela.comando(direcao);
      await tester.pump();
      expect(tela.itemSelecionado, item);
      expect(tela.etapaDoCartao, EtapaCartao.recolhendo);
      await tester.pump(const Duration(milliseconds: 120));
      final recolhendo = find.byWidgetPredicate(
          (w) => w is PreviaCine && w.titulo.id == (item == 0 ? 4 : 5));
      expect(tester.getSize(recolhendo).width,
          closeTo(PreviaCine.tamanhoCartaz.width + PreviaCine.vao, .001));
      tela.comando(direcao); // durante o recolhimento não troca nem reabre
      expect(tela.itemSelecionado, item);
      await tester.pump(const Duration(milliseconds: 120));
      expect(tela.etapaDoCartao, EtapaCartao.parado);
      final card = tester.widget<LadrilhoCine>(
          find.byWidgetPredicate((w) => w is LadrilhoCine && w.selecionado));
      expect(card.virado, isFalse);
      tela.comando(direcao);
      await tester.pump();
      expect(tela.itemSelecionado, direcao == 'DIREITA' ? item + 1 : item - 1);
      // Baixo troca de faixa mesmo com a prévia aberta.
      await tester.pump(BodyCinemaState.ociosidade);
      await tester.pump(ViradaCine.duracao);
      await tester.pump();
      tela.comando('BAIXO');
      await tester.pump();
      expect(tela.faixaSelecionada, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      catalogo.dispose();
    });
  }

  testWidgets(
      'brilho atravessa os cantos e sai por inteiro em todos os formatos',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Center(
            child: BrilhoVarrido(
      ativo: true,
      child: SizedBox(width: 206, height: 309),
    ))));
    final painter = tester
        .widget<CustomPaint>(find.descendant(
            of: find.byType(BrilhoVarrido), matching: find.byType(CustomPaint)))
        .painter!;
    const tamanhos = [
      Size(206, 309),
      Size(420, 236),
      Size(208, 300),
      Size(232, 232)
    ];
    final inicioVisto = <Size>{};
    final fimVisto = <Size>{};
    for (var quadro = 0; quadro <= 9; quadro++) {
      if (quadro > 0) await tester.pump(const Duration(milliseconds: 100));
      for (final tamanho in tamanhos) {
        final pixels = await tester.runAsync(() async {
          final gravacao = ui.PictureRecorder();
          painter.paint(Canvas(gravacao), tamanho);
          final desenho = gravacao.endRecording();
          final imagem = await desenho.toImage(
              tamanho.width.toInt(), tamanho.height.toInt());
          final bytes =
              (await imagem.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          final largura = tamanho.width.toInt();
          final altura = tamanho.height.toInt();
          final inicio = bytes.getUint8((largura + 1) * 4 + 3);
          final fim =
              bytes.getUint8(((altura - 2) * largura + largura - 2) * 4 + 3);
          var aceso = false;
          for (var i = 3; i < bytes.lengthInBytes; i += 4) {
            if (bytes.getUint8(i) > 0) {
              aceso = true;
              break;
            }
          }
          imagem.dispose();
          desenho.dispose();
          return (inicio: inicio, fim: fim, aceso: aceso);
        });
        if (pixels!.inicio > 0) inicioVisto.add(tamanho);
        if (pixels.fim > 0) fimVisto.add(tamanho);
        if (quadro == 0 || quadro == 9) {
          expect(pixels.aceso, isFalse,
              reason: 'sem faixa parada no fim em $tamanho');
        }
      }
    }
    expect(inicioVisto, containsAll(tamanhos));
    expect(fimVisto, containsAll(tamanhos));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('vizinhos do mosaico respeitam colunas, linhas e grupos incompletos',
      () {
    int? vizinho(int i, Axis eixo, int passo,
            {int quantidade = 8, double? linha}) =>
        MedidaCine.vizinhoMosaico(quantidade, i,
            eixo: eixo, passo: passo, linha: linha);
    expect(vizinho(1, Axis.vertical, 1), 2);
    expect(vizinho(2, Axis.vertical, -1), 1);
    expect(vizinho(1, Axis.horizontal, 1), 3);
    expect(vizinho(2, Axis.horizontal, -1), 0);
    expect(vizinho(3, Axis.horizontal, -1, linha: 228), 2);
    expect(vizinho(5, Axis.vertical, 1), 6);
    expect(vizinho(6, Axis.horizontal, 1), 7);
    expect(vizinho(0, Axis.vertical, 1), isNull);
    expect(vizinho(2, Axis.vertical, 1), isNull);
    expect(vizinho(1, Axis.vertical, 1, quantidade: 2), isNull);
    expect(vizinho(0, Axis.horizontal, -1), isNull);
  });

  testWidgets('Pad percorre empilhados antes de sair de Aclamados',
      (tester) async {
    final catalogo = CinemaCatalogo(fonte: FonteMosaicoPad());
    final tela = await _montarTela(tester, catalogo: catalogo);
    for (var i = 0; i < 4; i++) {
      tela.comando('BAIXO');
      await tester.pump(const Duration(milliseconds: 500));
    }
    tela.comando('DIREITA');
    await tester.pump();
    expect(tela.itemSelecionado, 1);
    tela.comando('BAIXO');
    await tester.pump();
    expect(tela.faixaSelecionada, 4);
    expect(tela.itemSelecionado, 2);
    tela.comando('DIREITA');
    await tester.pump();
    expect(tela.itemSelecionado, 3);
    tela.comando('ESQUERDA');
    await tester.pump();
    expect(tela.itemSelecionado, 2,
        reason: 'preserva a linha ao atravessar o card alto');
    tela.comando('CIMA');
    await tester.pump();
    expect(tela.itemSelecionado, 1);
    expect(tela.faixaSelecionada, 4);
    tela.comando('CIMA');
    await tester.pump();
    expect(tela.faixaSelecionada, 3);
    tela.comando('BAIXO');
    await tester.pump();
    tela.comando('BAIXO');
    await tester.pump();
    expect(tela.faixaSelecionada, 4);
    expect(tela.itemSelecionado, 2);
    tela.comando('BAIXO');
    await tester.pump();
    expect(tela.faixaSelecionada, 5);
    await _descansar(tester);
    catalogo.dispose();
  });

  testWidgets(
      'catálogo e detalhes permanecem em cache entre acessos e montagens',
      (tester) async {
    final fonte = FonteFalsa();
    final catalogo = CinemaCatalogo(fonte: fonte);
    final tela = await _montarTela(tester, catalogo: catalogo);
    await tester.pump(const Duration(milliseconds: 600));
    expect(fonte.cargas, 1);
    expect(fonte.detalhes, 1);
    expect(
        find.descendant(
            of: find.byType(LogoDestaqueCine), matching: find.byType(Text)),
        findsNothing);
    tela.widget.ctrl.selectedIndexAbaGuias = 0;
    await tester.pump();
    tela.widget.ctrl.selectedIndexAbaGuias = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpWidget(const SizedBox.shrink());
    await _montarTela(tester, catalogo: catalogo);
    await tester.pump(const Duration(milliseconds: 600));
    expect(fonte.cargas, 1);
    expect(fonte.detalhes, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    catalogo.dispose();
  });

  testWidgets('cartaz sai primeiro, trailer depois; verso fica na mesma altura',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget montar({bool aberto = false, bool virado = false}) => MaterialApp(
          home: Scaffold(
              body: Align(
            alignment: Alignment.topLeft,
            child: LadrilhoCine(
              titulo: _titulo(42, 'Teste'),
              forma: FormaCine.poster,
              selecionado: true,
              indice: 0,
              tamanho: MedidaCine.poster,
              virado: virado,
              expandido: aberto,
              onAbrir: () {},
            ),
          )),
        );
    await tester.pumpWidget(montar());
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final verso = find.byType(ViradaCine);
    final antes = tester.getRect(verso);
    await tester.pumpWidget(montar(virado: true));
    await tester.pump(const Duration(milliseconds: 150));
    final rotacao = tester
        .widget<Transform>(
            find.descendant(of: verso, matching: find.byType(Transform)).first)
        .transform;
    expect(rotacao.entry(3, 2), 0, reason: 'sem perspectiva elevando a borda');
    expect(tester.getRect(verso), antes);
    await tester.pump(ViradaCine.duracao);
    await tester.pumpWidget(montar(virado: true, aberto: true));
    await tester.pump(const Duration(milliseconds: 230));
    expect(tester.getSize(find.byType(PreviaCine)).width,
        inExclusiveRange(0, MedidaCine.poster.width + PreviaCine.vao));
    await tester.pump(const Duration(milliseconds: 230));
    expect(tester.getSize(find.byType(PreviaCine)).width,
        MedidaCine.poster.width + PreviaCine.vao);
    expect(tester.getRect(verso), antes);
    await tester.pump(const Duration(milliseconds: 230));
    expect(
        tester.getSize(find.byType(PreviaCine)).width,
        inExclusiveRange(
            MedidaCine.poster.width + PreviaCine.vao, PreviaCine.espaco));
    await tester.pump(const Duration(milliseconds: 230));
    expect(tester.getSize(find.byType(PreviaCine)).width, PreviaCine.espaco);
    expect(tester.getSize(find.byKey(const ValueKey('previa-cartaz'))),
        MedidaCine.poster);
    final video = tester.getSize(find.byKey(const ValueKey('previa-trailer')));
    expect(video.width / video.height, closeTo(16 / 9, .0001));
    expect(video.height, MedidaCine.poster.height);
    expect(tester.getRect(verso), antes);
    await tester.pumpWidget(montar());
    await tester.pump();
    await tester.pump(PreviaCine.recolhimento);
    expect(tester.getSize(find.byType(PreviaCine)).width, 0);
    // O último frame zera a largura; o seguinte descarta o conteúdo.
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const ValueKey('previa-cartaz')), findsNothing);
    expect(find.byKey(const ValueKey('previa-trailer')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  group('geometria do mosaico', () {
    test('monta grupos de quatro com tamanhos diferentes', () {
      final geo = MedidaCine.geometriaMosaico(8);
      expect(geo, hasLength(8));
      // Bloco grande, dois pequenos empilhados na mesma coluna e um alto.
      expect(geo[0].width, greaterThan(geo[1].width));
      expect(geo[1].left, geo[2].left);
      expect(geo[2].top, greaterThan(geo[1].top));
      expect(geo[3].height, MedidaCine.mosaico);
      // O grupo seguinte começa depois do anterior, sem sobrepor.
      expect(geo[4].left, greaterThanOrEqualTo(geo[3].right));
    });

    test('lista curta não inventa retângulo', () {
      expect(MedidaCine.geometriaMosaico(0), isEmpty);
      expect(MedidaCine.geometriaMosaico(2), hasLength(2));
      expect(MedidaCine.geometriaMosaico(2).last.height,
          lessThan(MedidaCine.mosaico));
    });
  });

  group('catálogo', () {
    test('falha da fonte cai na demonstração e diz o motivo', () async {
      final catalogo = CinemaCatalogo(
          fonte: FonteFalsa(erro: const ErroCine('Falta a chave do TMDB.')));
      await catalogo.recarregar();
      expect(catalogo.demonstracao, isTrue);
      expect(catalogo.aviso, contains('chave'));
      expect(catalogo.faixas, isNotEmpty,
          reason: 'a tela nunca fica vazia por falta de chave');
      catalogo.dispose();
    });

    test('detalhar troca o título dentro das faixas e não repete o pedido',
        () async {
      final fonte = FonteFalsa(trailer: 'abc123');
      final catalogo = CinemaCatalogo(fonte: fonte);
      await catalogo.recarregar();

      final antes = catalogo.faixas.first.itens.first;
      expect(antes.trailer, isNull);

      final completo = await catalogo.detalhar(antes);
      expect(completo.trailer, 'abc123');
      expect(catalogo.faixas.first.itens.first.trailer, 'abc123',
          reason: 'a grade e a ficha não podem discordar');

      await catalogo.detalhar(antes);
      expect(fonte.detalhes, 1, reason: 'a segunda abertura usa o cache');
      catalogo.dispose();
    });
  });

  group('TMDB', () {
    test('lê a lista, nomeia os gêneros e escolhe o trailer em português',
        () async {
      final pedidos = <Uri>[];
      final cliente = MockClient((requisicao) async {
        pedidos.add(requisicao.url);
        final caminho = requisicao.url.path;
        if (caminho.endsWith('/genre/movie/list') ||
            caminho.endsWith('/genre/tv/list')) {
          return http.Response(
              jsonEncode({
                'genres': [
                  {'id': 28, 'name': 'Ação'}
                ]
              }),
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8'
              });
        }
        if (caminho.contains('/movie/9')) {
          return http.Response(
              jsonEncode({
                'id': 9,
                'overview': 'Sinopse longa.',
                'genres': [
                  {'name': 'Drama'}
                ],
                'images': {
                  'logos': [
                    {'iso_639_1': 'en', 'file_path': '/en.png'},
                    {'iso_639_1': 'pt', 'file_path': '/pt.png'},
                  ]
                },
                'videos': {
                  'results': [
                    {
                      'site': 'YouTube',
                      'type': 'Teaser',
                      'iso_639_1': 'pt',
                      'key': 'teaser'
                    },
                    {
                      'site': 'YouTube',
                      'type': 'Trailer',
                      'iso_639_1': 'pt',
                      'key': 'trailerPT'
                    },
                  ]
                },
                'watch/providers': {
                  'results': {
                    'BR': {
                      'link': 'https://tmdb/assistir',
                      'flatrate': [
                        {'provider_name': 'Netflix', 'logo_path': '/n.png'}
                      ]
                    }
                  }
                },
              }),
              200,
              headers: const {
                'content-type': 'application/json; charset=utf-8'
              });
        }
        return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 9,
                  'title': 'Filme Um',
                  'overview': 'Curta.',
                  'poster_path': '/p.jpg',
                  'backdrop_path': '/b.jpg',
                  'vote_average': 8.25,
                  'release_date': '2024-05-01',
                  'genre_ids': [28],
                },
                {
                  'id': 10,
                  'title': 'Sem arte',
                  'overview': '',
                },
              ]
            }),
            200,
            headers: const {'content-type': 'application/json; charset=utf-8'});
      });

      final fonte = TmdbFonte(chave: 'chave-de-teste', cliente: cliente);
      final faixas = await fonte.carregar();

      expect(faixas, isNotEmpty);
      final primeiro = faixas.first.itens.first;
      expect(primeiro.titulo, 'Filme Um');
      expect(primeiro.generos, ['Ação']);
      expect(primeiro.notaTexto, '8.3');
      expect(primeiro.ano, '2024');
      expect(faixas.first.itens.where((t) => t.id == 10), isEmpty,
          reason: 'título sem nenhuma arte deixaria buraco na faixa');
      expect(pedidos.first.queryParameters['api_key'], 'chave-de-teste');
      expect(pedidos.first.queryParameters['language'], 'pt-BR');

      final completo = await fonte.detalhar(primeiro);
      expect(completo.trailer, 'trailerPT',
          reason: 'trailer vem antes do teaser');
      expect(completo.logo, '/pt.png');
      expect(completo.sinopse, 'Sinopse longa.');
      expect(completo.provedores.single.nome, 'Netflix');
      expect(completo.ondeAssistir, 'https://tmdb/assistir');
      fonte.dispose();
    });

    test('chave recusada vira erro legível', () async {
      final fonte = TmdbFonte(
        chave: 'errada',
        cliente: MockClient((_) async => http.Response('{}', 401)),
      );
      await expectLater(
        fonte.carregar(),
        throwsA(isA<ErroCine>()
            .having((e) => e.mensagem, 'mensagem', contains('recusada'))),
      );
      fonte.dispose();
    });

    test('token v4 vai no cabeçalho, e não na query', () async {
      String? autorizacao;
      Uri? pedido;
      final fonte = TmdbFonte(
        chave: 'eyTokenFalso',
        cliente: MockClient((requisicao) async {
          autorizacao = requisicao.headers['Authorization'];
          pedido = requisicao.url;
          return http.Response(jsonEncode({'genres': [], 'results': []}), 200,
              headers: const {
                'content-type': 'application/json; charset=utf-8'
              });
        }),
      );
      await fonte.carregar().catchError((_) => <FaixaCine>[]);
      expect(autorizacao, 'Bearer eyTokenFalso');
      expect(pedido!.queryParameters.containsKey('api_key'), isFalse);
      fonte.dispose();
    });
  });

  group('ações da ficha', () {
    test('só oferecem o que o título tem', () {
      expect(FichaCine.acoesDe(_titulo(1, 'Um')),
          [AcaoFicha.ondeAssistir, AcaoFicha.fechar]);
      final completo = _titulo(1, 'Um')
          .copiaCom(trailer: 'xyz', ondeAssistir: 'https://exemplo');
      expect(FichaCine.acoesDe(completo),
          [AcaoFicha.trailer, AcaoFicha.ondeAssistir, AcaoFicha.fechar]);
    });
  });

  group('tela', () {
    testWidgets('desenha as faixas do catálogo e os canais na coluna',
        (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      await _montarTela(tester, catalogo: catalogo, canais: [
        MediaCanal(nome: 'Netflix', url: 'https://netflix', imgLocal: ''),
        MediaCanal(nome: 'Max', url: 'https://max', imgLocal: ''),
      ]);

      expect(find.text('Em alta'), findsOneWidget);
      expect(find.text('Cartazes'), findsOneWidget);
      expect(find.byType(TrilhoCanais), findsOneWidget);
      expect(find.byType(LadrilhoCine), findsWidgets);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('direcional anda na faixa, troca de faixa e sai para os canais',
        (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester, catalogo: catalogo, canais: [
        MediaCanal(nome: 'Netflix', url: 'https://netflix', imgLocal: ''),
      ]);

      expect(tela.comando('DIREITA'), isTrue);
      await tester.pump();
      expect(tela.itemSelecionado, 1);

      // Ponta direita não passa do último item.
      expect(tela.comando('DIREITA'), isTrue);
      expect(tela.comando('DIREITA'), isTrue);
      await tester.pump();
      expect(tela.itemSelecionado, 2);

      expect(tela.comando('BAIXO'), isTrue);
      await tester.pump();
      expect(tela.faixaSelecionada, 1);
      expect(tela.itemSelecionado, 1,
          reason: 'faixa mais curta prende o índice na última coluna');

      // Até a primeira coluna, e daí para a coluna de canais.
      tela.comando('ESQUERDA');
      await tester.pump();
      expect(tela.zona, ZonaCine.mosaico);
      tela.comando('ESQUERDA');
      await tester.pump();
      expect(tela.zona, ZonaCine.canais);

      // De volta ao mosaico pela direita.
      tela.comando('DIREITA');
      await tester.pump();
      expect(tela.zona, ZonaCine.mosaico);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('A abre a ficha no mosaico e devolve o comando nos canais',
        (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester, catalogo: catalogo, canais: [
        MediaCanal(nome: 'Netflix', url: 'https://netflix', imgLocal: ''),
      ]);

      await _irParaOsCartazes(tester, tela);
      expect(tela.comando('2'), isTrue);
      await tester.pump();
      expect(find.byType(FichaCine), findsOneWidget);

      // Com a ficha aberta, B fecha e o mosaico volta.
      expect(tela.comando('3'), isTrue);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tela.fichaAberta, isNull);

      // Na coluna de canais, A não é consumido: quem abre o streaming é o
      // PrincipalCtrl, com o código que já existia.
      tela.comando('ESQUERDA');
      tela.comando('ESQUERDA');
      await tester.pump();
      expect(tela.zona, ZonaCine.canais);
      expect(tela.comando('2'), isFalse);
      expect(tela.comando('SELECT'), isFalse);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('cima na primeira faixa entra na coluna de canais',
        (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester, catalogo: catalogo, canais: [
        MediaCanal(
            nome: 'Netflix', url: 'https://www.netflix.com', imgLocal: ''),
        MediaCanal(nome: 'Max', url: 'https://max.com', imgLocal: ''),
      ]);

      // Sem precisar voltar coluna por coluna até a primeira.
      tela.comando('DIREITA');
      tela.comando('DIREITA');
      await tester.pump();
      expect(tela.comando('CIMA'), isTrue);
      await tester.pump();
      expect(tela.zona, ZonaCine.canais);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('canal apontado toma o miolo da tela e funde na troca',
        (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester, catalogo: catalogo, canais: [
        MediaCanal(
            nome: 'Netflix', url: 'https://www.netflix.com', imgLocal: ''),
        MediaCanal(nome: 'Max', url: 'https://max.com', imgLocal: ''),
      ]);

      double opacidadeDoCatalogo() => tester
          .widget<AnimatedOpacity>(find.byKey(const ValueKey('catalogo')))
          .opacity;

      double opacidadeDaCapa() => tester
          .widget<AnimatedOpacity>(find.byKey(const ValueKey('capa-canal')))
          .opacity;

      expect(opacidadeDoCatalogo(), 1, reason: 'no mosaico o catálogo manda');
      expect(opacidadeDaCapa(), 0);

      tela.comando('ESQUERDA');
      await tester.pump();
      expect(tela.zona, ZonaCine.canais);
      expect(opacidadeDoCatalogo(), 0,
          reason: 'o miolo passa a ser a capa do canal');
      expect(opacidadeDaCapa(), 1);
      expect(find.byType(TrilhoCanais), findsOneWidget,
          reason: 'a coluna nunca sai: é nela que se vê o que está escolhido');
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('canal-0')), findsOneWidget);

      // Trocar de canal cruza as duas capas: uma entra enquanto a outra sai.
      tela.comando('BAIXO');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byKey(const ValueKey('canal-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('canal-1')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('canal-0')), findsNothing);

      // De volta ao mosaico, o catálogo volta.
      tela.comando('DIREITA');
      await tester.pump();
      expect(opacidadeDoCatalogo(), 1);
      expect(opacidadeDaCapa(), 0);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('coluna de canais não escreve rótulo nenhum', (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      await _montarTela(tester, catalogo: catalogo, canais: [
        MediaCanal(
            nome: 'Netflix', url: 'https://www.netflix.com', imgLocal: ''),
      ]);
      expect(find.text('CANAIS'), findsNothing);
      expect(find.text('NETFLIX.COM'), findsNothing);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('não imprime dica de navegação na tela', (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      await _montarTela(tester, catalogo: catalogo, canais: [
        MediaCanal(
            nome: 'Netflix', url: 'https://www.netflix.com', imgLocal: ''),
      ]);
      expect(find.textContaining('direcional'), findsNothing);
      expect(find.textContaining('abrir ficha'), findsNothing);
      expect(find.textContaining('START'), findsNothing);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('alcança os canais mesmo sem catálogo na tela', (tester) async {
      // Nada carregado ainda: sem isto a coluna ficaria inalcançável
      // justamente enquanto não há mais nada para fazer na tela.
      final catalogo = CinemaCatalogo(
          fonte: FonteFalsa(erro: const ErroCine('fora do ar')),
          reserva: () => FonteFalsa(erro: const ErroCine('fora do ar')));
      final tela = await _montarTela(tester, catalogo: catalogo, canais: [
        MediaCanal(
            nome: 'Netflix', url: 'https://www.netflix.com', imgLocal: ''),
      ]);
      expect(catalogo.faixas, isEmpty);

      expect(tela.comando('ESQUERDA'), isTrue);
      await tester.pump();
      expect(tela.zona, ZonaCine.canais);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('só o cartaz e o bloco pequeno viram; o resto fica parado',
        (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester, catalogo: catalogo);

      Future<void> esperarOCiclo() async {
        await tester.pump(BodyCinemaState.ociosidade);
        await tester.pump();
        await tester.pump(ViradaCine.duracao);
        await tester.pump();
      }

      // Quadro largo: a arte é o conteúdo, não vira.
      expect(tela.faixaSelecionada, 0);
      await esperarOCiclo();
      expect(tela.etapaDoCartao, EtapaCartao.parado);

      // Cartaz: vira e abre a prévia.
      tela.comando('BAIXO');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(BodyCinemaState.ociosidade);
      await tester.pump();
      expect(tela.etapaDoCartao, EtapaCartao.virado);
      await tester.pump(ViradaCine.duracao);
      await tester.pump();
      expect(tela.etapaDoCartao, EtapaCartao.aberto);
      expect(find.byType(PreviaCine), findsWidgets);

      // O primeiro toque recolhe, o próximo navega.
      await tester.pump(PreviaCine.duracao);
      tela.comando('DIREITA');
      await tester.pump();
      expect(tela.etapaDoCartao, EtapaCartao.recolhendo);
      expect(tela.itemSelecionado, 0);
      await tester.pump(PreviaCine.recolhimento);
      expect(tela.etapaDoCartao, EtapaCartao.parado);
      tela.comando('DIREITA');
      await tester.pump();
      expect(tela.itemSelecionado, 1);

      // Quadrado e círculo também ficam parados.
      for (final faixa in [2, 3]) {
        tela.comando('BAIXO');
        await tester.pump(const Duration(milliseconds: 500));
        expect(tela.faixaSelecionada, faixa);
        await esperarOCiclo();
        expect(tela.etapaDoCartao, EtapaCartao.parado);
      }

      // Mosaico: o bloco grande é o primeiro e não vira; o seguinte, menor,
      // vira e abre o trailer no enquadramento do bloco grande. O índice
      // vem herdado da faixa anterior, então volta-se ao primeiro bloco
      // antes de medir.
      tela.comando('BAIXO');
      await tester.pump(const Duration(milliseconds: 500));
      expect(tela.faixaSelecionada, 4);
      tela.comando('ESQUERDA');
      await tester.pump(const Duration(milliseconds: 300));
      expect(tela.itemSelecionado, 0);
      await esperarOCiclo();
      expect(tela.etapaDoCartao, EtapaCartao.parado);

      tela.comando('DIREITA');
      await tester.pump(const Duration(milliseconds: 300));
      await esperarOCiclo();
      expect(tela.etapaDoCartao, EtapaCartao.aberto);
      final previa = tester.widget<PreviaCine>(find.byType(PreviaCine));
      expect(previa.aberta, isTrue);
      await tester.pump(PreviaCine.duracao);
      await tester.pump();
      expect(tester.getSize(find.byKey(const ValueKey('previa-cartaz'))),
          MedidaCine.poster);
      final video =
          tester.getSize(find.byKey(const ValueKey('previa-trailer')));
      expect(video.width / video.height, closeTo(16 / 9, .0001));
      expect(video.height, MedidaCine.poster.height);
      final vizinho = tester.getRect(find.byKey(const ValueKey('mosaico-4-3')));
      final trailer =
          tester.getRect(find.byKey(const ValueKey('previa-trailer')));
      expect(vizinho.left, greaterThanOrEqualTo(trailer.right));

      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('fora de vista o ciclo não começa', (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester, catalogo: catalogo);
      tela.comando('BAIXO'); // faixa dos cartazes, que vira
      await tester.pump(const Duration(milliseconds: 500));

      tela.widget.ctrl.selectedIndexAbaGuias = 0;
      await tester.pump();
      await tester.pump(BodyCinemaState.ociosidade + ViradaCine.duracao);
      await tester.pump();
      expect(tela.etapaDoCartao, EtapaCartao.parado);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('faixa com reflexo não quebra a semântica ao ser percorrida',
        (tester) async {
      // O reflexo desenha o mesmo cartão duas vezes. Com a cópia dentro da
      // árvore de semântica, percorrer a faixa derrubava a compilação em
      // `!semantics.parentDataDirty` — e o launcher roda com a semântica
      // ligada. Qualquer exceção aqui reprova o teste.
      final semantica = tester.ensureSemantics();
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester, catalogo: catalogo);

      tela.comando('BAIXO');
      await tester.pump();
      tela.comando('BAIXO');
      await tester.pump(const Duration(milliseconds: 500));
      expect(tela.faixaSelecionada, 2);

      for (var i = 0; i < 3; i++) {
        tela.comando('DIREITA');
        await tester.pump(const Duration(milliseconds: 200));
      }
      // Parado, o quadrado não vira — mas o espelho segue redesenhando.
      await tester.pump(BodyCinemaState.ociosidade);
      await tester.pump(ViradaCine.duracao);
      await tester.pump(const Duration(milliseconds: 500));

      await _descansar(tester);
      catalogo.dispose();
      semantica.dispose();
    });

    testWidgets('ficha leva ao player, B traz o texto de volta e A retoma',
        (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa(trailer: 'abc123'));
      final tela = await _montarTela(tester, catalogo: catalogo);

      await _irParaOsCartazes(tester, tela);
      tela.comando('2'); // abre a ficha
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tela.zonaDaFicha, ZonaFicha.acoes);
      expect(tela.acaoDaFicha, AcaoFicha.trailer);

      tela.comando('2'); // confirma o trailer
      await tester.pump();
      expect(tela.zonaDaFicha, ZonaFicha.player);

      // No player, LB/RB são salto de vídeo — e não troca de aba.
      expect(tela.comando('RB'), isTrue);
      expect(tela.comando('LB'), isTrue);

      // B sai do player sem fechar a ficha nem parar o trailer.
      expect(tela.comando('3'), isTrue);
      await tester.pump();
      expect(tela.zonaDaFicha, ZonaFicha.acoes);
      expect(tela.fichaAberta, isNotNull);

      // A na mesma ação devolve a tela ao player.
      tela.comando('2');
      await tester.pump();
      expect(tela.zonaDaFicha, ZonaFicha.player);

      // Fora do player, LB/RB voltam a ser troca de aba: a ficha fecha e o
      // comando segue para o PrincipalCtrl.
      tela.comando('3');
      await tester.pump();
      expect(tela.comando('RB'), isFalse);
      expect(tela.fichaAberta, isNull);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('serviço de streaming é alvo do direcional e copia o nome',
        (tester) async {
      final copiados = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (chamada) async {
          if (chamada.method == 'Clipboard.setData') {
            copiados.add((chamada.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      final catalogo = CinemaCatalogo(
          fonte: FonteFalsa(trailer: 'abc123', provedores: const [
        ProvedorCine(nome: 'Netflix'),
        ProvedorCine(nome: 'Max'),
      ]));
      final abertos = <String>[];
      final tela = await _montarTela(tester,
          catalogo: catalogo,
          abertos: abertos,
          canais: [
            MediaCanal(
                nome: 'Netflix', url: 'https://netflix.conta', imgLocal: ''),
          ]);

      await _irParaOsCartazes(tester, tela);
      tela.comando('2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Desce das ações para a faixa de serviços e anda nela.
      expect(tela.comando('BAIXO'), isTrue);
      await tester.pump();
      expect(tela.zonaDaFicha, ZonaFicha.provedores);
      expect(tela.provedorSelecionado, 0);
      tela.comando('DIREITA');
      await tester.pump();
      expect(tela.provedorSelecionado, 1);
      tela.comando('ESQUERDA');
      await tester.pump();

      // Confirmar copia o nome do filme — é o que se cola na busca do
      // serviço — e o endereço sai do cartão de canal do próprio usuário.
      expect(
          tela.enderecoDoProvedorParaTeste(const ProvedorCine(nome: 'Netflix')),
          'https://netflix.conta');
      expect(tela.enderecoDoProvedorParaTeste(const ProvedorCine(nome: 'Max')),
          contains('max.com'));

      expect(find.byKey(const ValueKey('ficha-trailer')), findsOneWidget);
      expect(find.byKey(const ValueKey('ficha-voltar')), findsOneWidget);
      expect(find.text('A  trailer'), findsNothing);
      expect(find.text('A  onde assistir'), findsNothing);
      expect(find.text('B  voltar'), findsNothing);
      expect(find.byKey(const ValueKey('ficha-onde-assistir')), findsNothing);
      expect(find.byKey(const ValueKey('ficha-google')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('ficha-provedor-0')));
      await tester.pump();
      await tester.pump();
      expect(copiados, ['Quatro'], reason: 'o cartaz em foco é o quarto');
      expect(abertos, ['https://netflix.conta']);
      expect(find.text('“Quatro” copiado · abrindo Netflix'), findsOneWidget);

      // Cima volta para as ações.
      tela.comando('CIMA');
      await tester.pump();
      expect(tela.zonaDaFicha, ZonaFicha.acoes);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('círculo entra e sai de foco sem raio de sombra negativo',
        (tester) async {
      // A curva do círculo é `easeOutBack`: ela passa de 1 na ida e abaixo
      // de zero na volta. Multiplicada direto no raio da sombra, dava raio
      // negativo — erro de verdade, que trocava o cartão por um ErrorWidget
      // de 100000 px e estourava a faixa inteira.
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester, catalogo: catalogo);

      for (var i = 0; i < 3; i++) {
        tela.comando('BAIXO');
        await tester.pump(const Duration(milliseconds: 500));
      }
      expect(tela.faixaSelecionada, 3);

      // Entra num círculo e sai dele, acompanhando a volta quadro a quadro.
      tela.comando('DIREITA');
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      tela.comando('ESQUERDA');
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(tela.itemSelecionado, 0);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets(
        'o trailer do destaque toca sozinho, sem precisar confirmar, e A abre a ficha direto',
        (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa(trailer: 'abc123'));
      final tela = await _montarTela(tester, catalogo: catalogo);
      expect(tela.faixaSelecionada, 0);

      // Nenhum comando: só selecionar o cartão já basta. O trailer chega
      // pela ficha detalhada, buscada sozinha ~450ms depois da seleção.
      expect(tela.trailerDestaqueVisivel, isTrue);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TrailerCine), findsWidgets);

      // A abre a ficha direto, sem passo intermediário.
      expect(tela.comando('2'), isTrue);
      await tester.pump();
      expect(tela.fichaAberta, isNotNull);
      expect(tela.trailerDestaqueVisivel, isFalse,
          reason: 'com a ficha aberta a caixa do destaque some');

      tela.comando('3');
      await tester.pump();
      expect(tela.trailerDestaqueVisivel, isTrue,
          reason: 'fechar a ficha devolve a caixa ao destaque');

      // Fora da faixa de destaque, a caixa não existe.
      await _irParaOsCartazes(tester, tela);
      expect(tela.trailerDestaqueVisivel, isFalse);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('cabe em monitor pequeno, com a ficha aberta', (tester) async {
      final catalogo = CinemaCatalogo(fonte: FonteFalsa());
      final tela = await _montarTela(tester,
          catalogo: catalogo, janela: const Size(1024, 640));
      // Estouro de layout vira exceção e derruba o teste — é o que se quer
      // vigiar aqui, numa janela menor que a do desenvolvimento.
      expect(find.byType(LadrilhoCine), findsWidgets);
      await _irParaOsCartazes(tester, tela);
      tela.comando('2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(FichaCine), findsOneWidget);
      await _descansar(tester);
      catalogo.dispose();
    });

    testWidgets('ficha aberta prende o direcional e troca a ação em foco',
        (tester) async {
      // A ficha aberta cancela o ciclo do cartão, então aqui um trailer não
      // faz player nenhum subir.
      final catalogo = CinemaCatalogo(fonte: FonteFalsa(trailer: 'abc123'));
      final tela = await _montarTela(tester, catalogo: catalogo);

      await _irParaOsCartazes(tester, tela);
      final faixaAntes = tela.faixaSelecionada;
      tela.comando('2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tela.acaoDaFicha, AcaoFicha.trailer,
          reason: 'com trailer disponível, ele é a ação em foco');
      expect(tela.comando('BAIXO'), isTrue);
      expect(tela.faixaSelecionada, faixaAntes,
          reason: 'o mosaico não pode andar atrás de uma ficha que cobre tudo');

      tela.comando('DIREITA');
      await tester.pump();
      expect(tela.acaoDaFicha, AcaoFicha.ondeAssistir);
      await _descansar(tester);
      catalogo.dispose();
    });
  });
}
