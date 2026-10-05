// ignore_for_file: file_names
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../Interface/launcher_pad_scope.dart';
import '../../../Controllers/launcher_window_controller.dart';
import '../PrincipalCtrl.dart';

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
        3 => '',
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
                          (constraints.maxHeight * .55).clamp(64.0, 144.0);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xCC000000),
                                    Color(0x66000000),
                                    Colors.transparent
                                  ],
                                  stops: [0, .35, 1],
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
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left:
                                        8 / LauncherWindowController.slimScale,
                                    right: 260,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _usageBar(),
                                  ),
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

  Widget _usageBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _categories(),
            const SizedBox(width: 10),
            const SizedBox(
              height: 18,
              child: VerticalDivider(width: 1, color: Colors.white24),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Tooltip(
                message:
                    'LB / RB: categorias • A / Enter: abrir • Start / F10: menu',
                child: GestureDetector(
                  onTap: ctrl.mouseBloqueado ? null : ctrl.abrirMenuSlim,
                  child: const Text(
                    'LB / RB  Categorias     A / Enter  Abrir     Start / F10  Menu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

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
        itemExtent: widget.width + 16,
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
                margin: const EdgeInsets.only(right: 16, top: 6, bottom: 2),
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
                                    ),
                                  )),
                            ),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2, left: 2, right: 2),
                      child: Visibility(
                        visible: ctrl.slimItemNodes[index].hasFocus,
                        maintainSize: true,
                        maintainState: true,
                        maintainAnimation: true,
                        child: Text(widget.name(index),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: selected ? Colors.white : Colors.white70,
                                fontSize: 12,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 6)
                                ])),
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
  const _SlimImage({required this.path, required this.icon, this.color});
  final String path;
  final IconData icon;
  final Color? color;

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
