// ignore_for_file: file_names
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../Interface/launcher_pad_scope.dart';
import '../../../Controllers/launcher_window_controller.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';

/// Apresentação fixa do Slim. Dados e ações continuam no controlador principal.
class BodySlim extends StatelessWidget {
  const BodySlim({super.key, required this.ctrl});

  final PrincipalCtrl ctrl;
  static const _icons = [
    Icons.sports_esports_rounded,
    Icons.movie_rounded,
    Icons.music_note_rounded,
    Icons.storefront_rounded,
  ];
  static const _selectedColor = Color(0xFFB9F6CA);

  /// Cartão 5% menor e 15% mais perto do vizinho.
  ///
  /// Os dois andam juntos: encolher sem aproximar só aumenta o vazio entre
  /// eles. A folga original era de 16 pixels.
  static const escalaDoCartao = .95;
  static const folgaEntreCartoes = 16 * .85;

  /// Altura da barra inferior: categorias à esquerda, nome no meio.
  static const alturaDaBarraInferior = 30.0;

  /// Espaço que a legenda ocupava sob cada cartão; hoje guarda a bolinha.
  static const alturaDoNomeNoCartao = 18.0;

  /// A marca de "é este": uma bolinha branca sob o cartão escolhido.
  static const diametroDaBolinha = 7.0;
  static const _labels = ['Jogos', 'Cinema', 'Música', 'Loja'];
  static final _navigationKeys = {
    LogicalKeyboardKey.keyW: 'CIMA',
    LogicalKeyboardKey.keyS: 'BAIXO',
    LogicalKeyboardKey.keyA: 'ESQUERDA',
    LogicalKeyboardKey.keyD: 'DIREITA',
    LogicalKeyboardKey.backspace: '3',
  };

  String _name(int index) => switch (ctrl.selectedIndexAbaGuias) {
        1 => ctrl.listCinema[index].nome,
        2 => ctrl.listMusica[index].nome,
        3 => ctrl.listLojas[index].nome,
        _ => ctrl.listIconsInicial[index].nome,
      };

  String _image(int index) => switch (ctrl.selectedIndexAbaGuias) {
        1 => ctrl.listCinema[index].imgLocal,
        2 => ctrl.listMusica[index].imgLocal,
        3 => ctrl.listLojas[index].logo,
        _ => ctrl.listIconsInicial[index].imgStr,
      };

  @override
  Widget build(BuildContext context) {
    final category = ctrl.selectedIndexAbaGuias;
    final count = ctrl.slimItemNodes.length;
    final selected = count == 0 ? 0 : ctrl.slimItemIndex.clamp(0, count - 1);
    return LauncherPadScope(
      enabled: !ctrl.mouseBloqueado,
      revealInitialFocus: false,
      revealFocus: false,
      onCommand: ctrl.comandoSlim,
      child: Focus(
        skipTraversal: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          final key = event.logicalKey;
          final command = key == LogicalKeyboardKey.enter ||
                  key == LogicalKeyboardKey.numpadEnter ||
                  key == LogicalKeyboardKey.space ||
                  key == LogicalKeyboardKey.gameButtonA
              ? '2'
              : key == LogicalKeyboardKey.pageUp ||
                      key == LogicalKeyboardKey.keyQ
                  ? 'LB'
                  : key == LogicalKeyboardKey.pageDown ||
                          key == LogicalKeyboardKey.keyE
                      ? 'RB'
                      : event.character == '+' ||
                              key == LogicalKeyboardKey.numpadAdd
                          ? 'START'
                          : _navigationKeys[key];
          if (command == null) return KeyEventResult.ignored;
          // Evita abrir repetidamente um item ou um menu ao segurar a tecla.
          if (event is KeyDownEvent || command == 'LB' || command == 'RB') {
            ctrl.comandoSlim(command);
          }
          return KeyEventResult.handled;
        },
        child: LayoutBuilder(
            builder: (context, bounds) => FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: bounds.maxWidth / LauncherWindowController.slimScale,
                    height:
                        bounds.maxHeight / LauncherWindowController.slimScale,
                    child: LayoutBuilder(builder: (context, constraints) {
                      final width =
                          (constraints.maxHeight * .55).clamp(64.0, 144.0) *
                              escalaDoCartao;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // A base do gradiente é quase preta: é ela que
                          // sustenta a leitura dos ícones e do nome do item,
                          // no lugar da pílula escura que havia atrás deles.
                          // O escurecimento sobe devagar para não virar uma
                          // faixa com borda visível.
                          const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xF7000000),
                                    Color(0xE6000000),
                                    Color(0x99000000),
                                    Color(0x33000000),
                                    Colors.transparent,
                                  ],
                                  stops: [0, .18, .42, .7, 1],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          constraints.maxWidth < 600 ? 12 : 32,
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        FocusScope(
                                          node: ctrl.slimItemScope,
                                          child: count == 0
                                              ? const Center(
                                                  child: Text(
                                                      'Nenhum item. Adicione no modo Fat.',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          shadows: [
                                                            Shadow(
                                                                color: Colors
                                                                    .black,
                                                                blurRadius: 6)
                                                          ])))
                                              : _SlimItems(
                                                  key: ValueKey(category),
                                                  ctrl: ctrl,
                                                  width: width,
                                                  count: count,
                                                  selected: selected,
                                                  name: _name,
                                                  image: _image,
                                                  icon: _icons[category]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: alturaDaBarraInferior,
                                  child: Stack(children: [
                                    // O nome centraliza na largura inteira.
                                    // Centralizar no espaço que sobra depois
                                    // da reserva dos botões o jogaria para a
                                    // esquerda do meio da tela.
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 170),
                                        child: Center(
                                            child: _nomeDoItem(count, selected)),
                                      ),
                                    ),
                                    Positioned(
                                      left: 8 /
                                          LauncherWindowController.slimScale,
                                      top: 0,
                                      bottom: 0,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _usageBar(),
                                      ),
                                    ),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                )),
      ),
    );
  }

  /// Rodapé esquerdo: só onde a tela está.
  ///
  /// Antes era uma pílula preta com as categorias e, ao lado, a legenda de
  /// como navegar. A legenda saiu — ela repetia a cada quadro algo que se
  /// aprende uma vez — e com ela foi o fundo arredondado: quem dá contraste
  /// aos ícones agora é o próprio gradiente do rodapé, mais escuro na base.
  Widget _usageBar() => _categories();

  /// Nome do item em foco, no meio da barra inferior.
  ///
  /// Era uma legenda de 12 pixels embaixo de cada cartão, repetida na esteira
  /// e apertada na largura do ícone. No meio da barra ele tem a linha toda,
  /// aparece uma vez só e fica legível de longe — que é como o Slim é usado.
  Widget _nomeDoItem(int count, int selected) {
    if (count == 0) return const SizedBox.shrink();
    return Text(
      _name(selected),
      maxLines: 1,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        shadows: [Shadow(color: Colors.black, blurRadius: 6)],
      ),
    );
  }

  Widget _categories() => FocusScope(
        node: ctrl.focusScopeAbaGuias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_labels.length, (index) {
            final selected = ctrl.selectedIndexAbaGuias == index;
            return Tooltip(
              message: _labels[index],
              child: SizedBox(
                width: 36,
                child: Focus(
                  focusNode: ctrl.focusNodeAbaGuias[index],
                  onFocusChange: (focused) {
                    if (!focused || ctrl.mouseBloqueado) return;
                    ctrl.focusScope = ctrl.focusScopeAbaGuias;
                    if (!selected) {
                      ctrl.selecionarCategoriaSlim(index, barra: true);
                    }
                  },
                  child: GestureDetector(
                    onTap: ctrl.mouseBloqueado
                        ? null
                        : () => ctrl.selecionarCategoriaSlim(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 2),
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? _selectedColor.withValues(alpha: .15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected
                                ? ctrl.focusScopeAbaGuias.hasFocus
                                    ? _selectedColor
                                    : _selectedColor.withValues(alpha: .6)
                                : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_icons[index],
                              size: 20,
                              color: selected ? _selectedColor : Colors.white70,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 6)
                              ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
}

class _SlimItems extends StatefulWidget {
  const _SlimItems(
      {super.key,
      required this.ctrl,
      required this.width,
      required this.count,
      required this.selected,
      required this.name,
      required this.image,
      required this.icon});

  final PrincipalCtrl ctrl;
  final double width;
  final int count;
  final int selected;
  final String Function(int) name;
  final String Function(int) image;
  final IconData icon;

  @override
  State<_SlimItems> createState() => _SlimItemsState();
}

class _SlimItemsState extends State<_SlimItems> {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.selected * (widget.width + 16),
  );

  @override
  void didUpdateWidget(_SlimItems oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected ||
        oldWidget.width != widget.width) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.animateTo(
          (widget.selected * (widget.width + 16))
              .clamp(0.0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        itemExtent: widget.width + BodySlim.folgaEntreCartoes,
        itemCount: widget.count,
        itemBuilder: (context, index) {
          final ctrl = widget.ctrl;
          final selected = widget.selected == index;
          final store =
              ctrl.selectedIndexAbaGuias == 3 ? ctrl.listLojas[index] : null;
          return Focus(
            focusNode: ctrl.slimItemNodes[index],
            onFocusChange: (focused) {
              if (focused) {
                ctrl.selecionarItemSlim(index);
              } else {
                ctrl.attTela();
              }
            },
            child: GestureDetector(
              onTap: ctrl.mouseBloqueado
                  ? null
                  : () {
                      ctrl.selecionarItemSlim(index);
                      ctrl.abrirItemSlim();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(
                    right: BodySlim.folgaEntreCartoes, top: 6, bottom: 2),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: AnimatedScale(
                              scale: selected ? 1 : .88,
                              alignment: Alignment.bottomCenter,
                              duration: const Duration(milliseconds: 160),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: store == null
                                          ? null
                                          : LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                store.cor.withValues(
                                                    alpha:
                                                        selected ? .95 : .75),
                                                const Color(0xFF101827),
                                              ],
                                            ),
                                      border: store == null
                                          ? null
                                          : Border.all(
                                              color: selected
                                                  ? Colors.white54
                                                  : Colors.white12,
                                            ),
                                    ),
                                    child: _SlimImage(
                                      path: widget.image(index),
                                      icon: store?.icone ?? widget.icon,
                                      color:
                                          store == null ? null : Colors.white,
                                      logo: store != null,
                                    ),
                                  )),
                            ),
                          )),
                    ),
                    // O nome saiu daqui para o meio da barra inferior. O
                    // espaço continua reservado — sem ele o quadrado da capa
                    // cresce para ocupar a sobra e desfaz o tamanho de
                    // `escalaDoCartao` — e agora guarda a bolinha que marca
                    // qual cartão está escolhido.
                    SizedBox(
                      height: BodySlim.alturaDoNomeNoCartao,
                      child: Center(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          scale: selected ? 1 : 0,
                          child: Container(
                            width: BodySlim.diametroDaBolinha,
                            height: BodySlim.diametroDaBolinha,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black, blurRadius: 6)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _SlimImage extends StatelessWidget {
  const _SlimImage(
      {required this.path, required this.icon, this.color, this.logo = false});
  final String path;
  final IconData icon;
  final Color? color;

  /// Marca de loja: cabe inteira no bloco em vez de ser recortada.
  final bool logo;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Center(
        child: Icon(icon,
            size: 48,
            color: color ?? Colors.white,
            shadows: const [Shadow(color: Colors.black, blurRadius: 8)]));
    if (path.isEmpty) return fallback();
    final uri = Uri.tryParse(path);
    const decodeWidth = 320;
    // As logos vêm do pacote do aplicativo, não do disco do usuário.
    if (path.startsWith('assets/')) {
      return Padding(
        padding: EdgeInsets.all(logo ? 14 : 0),
        child: Image.asset(path,
            fit: logo ? BoxFit.contain : BoxFit.cover,
            cacheWidth: decodeWidth,
            errorBuilder: (_, __, ___) => fallback()),
      );
    }
    if (uri?.scheme == 'https' || uri?.scheme == 'http') {
      return Image.network(path,
          fit: BoxFit.cover,
          cacheWidth: decodeWidth,
          errorBuilder: (_, __, ___) => fallback());
    }
    return Image.file(File(path),
        fit: BoxFit.cover,
        cacheWidth: decodeWidth,
        errorBuilder: (_, __, ___) => fallback());
  }
}
