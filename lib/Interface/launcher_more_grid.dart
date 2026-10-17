import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Controllers/SonsSistema.dart';
import 'futuristic_material.dart';
import 'launcher_pad_scope.dart';

/// Result strings preserve the existing launcher's action contract.
class LauncherMoreGrid extends StatefulWidget {
  const LauncherMoreGrid(
      {super.key, this.scene, this.futuristic = false});
  final ui.Image? scene;
  final bool futuristic;
  @override
  State<LauncherMoreGrid> createState() => _LauncherMoreGridState();
}

class _LauncherMoreGridState extends State<LauncherMoreGrid> {
  static const items = [
    ('Downloads', 'Downloads', Icons.download_rounded),
    ('Adicionar jogo', 'Add', Icons.add_rounded),
    ('Buscar jogos', 'busca', Icons.search_rounded),
    ('Configurações', 'Cfg', Icons.settings_rounded),
    ('Pasta do jogo', 'Caminho do game', Icons.folder_rounded),
    ('Imagem local', 'Caminho de Imagem', Icons.image_rounded),
    ('Buscar imagens', 'Imagem da Download', Icons.image_search_rounded),
    ('Atalhos', 'Atalhos', Icons.shortcut_rounded),
    ('Excluir card', 'Excluir Card', Icons.delete_outline_rounded),
    ('Voltar', '', Icons.arrow_back_rounded),
  ];
  final _nodes = List.generate(items.length, (_) => FocusNode());
  final _scroll = ScrollController();
  int _selected = 0;
  bool _closed = false;
  static const stride = 106.0;

  void _close(String result) {
    if (_closed || !mounted) return;
    _closed = true;
    SonsSistema.click();
    Navigator.of(context).pop(result);
  }

  void _select(int index) {
    if (_closed || index == _selected) return;
    setState(() => _selected = index);
    SonsSistema.direction();
    _nodes[index].requestFocus();
    if (!_scroll.hasClients) return;
    final top = (index ~/ 2) * stride;
    final bottom = top + 94;
    final position = _scroll.position;
    final target = top < position.pixels
        ? top
        : bottom > position.pixels + position.viewportDimension
            ? bottom - position.viewportDimension
            : position.pixels;
    _scroll.animateTo(target.clamp(0.0, position.maxScrollExtent),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic);
  }

  bool _command(String command) {
    if (_closed) return true;
    switch (command) {
      case 'CIMA':
        if (_selected >= 2) _select(_selected - 2);
      case 'BAIXO':
        if (_selected + 2 < items.length) _select(_selected + 2);
      case 'ESQUERDA':
        if (_selected.isOdd) _select(_selected - 1);
      case 'DIREITA':
        if (_selected.isEven) _select(_selected + 1);
      case '2':
        _close(items[_selected].$2);
      case '3':
      case 'START':
        _close('');
    }
    return true;
  }

  Widget _panel(Widget child) {
    if (widget.futuristic) return GlassPanel(radius: 32, child: child);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF0181D27),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x40FFFFFF)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x70000000), blurRadius: 24, offset: Offset(0, 12))
          ],
        ),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialog = Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 560,
        height: (size.height - 48).clamp(160.0, 612.0),
        child: _panel(Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 18),
                        child: Text('Mais',
                            style: TextStyle(
                                color: widget.futuristic
                                    ? FuturisticPalette.pearl
                                    : Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w500))),
                    Expanded(
                        child: GridView.builder(
                      controller: _scroll,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 94,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12),
                      itemCount: items.length,
                      itemBuilder: (_, index) {
                        final selected = index == _selected;
                        final futuristicColors = selected
                            ? const [
                                Color(0xB08063BB),
                                Color(0x905A417F)
                              ]
                            : const [
                                Color(0x402F2946),
                                Color(0x70312645)
                              ];
                        return Focus(
                          focusNode: _nodes[index],
                          autofocus: index == 0,
                          onFocusChange: (focused) {
                            if (focused) _select(index);
                          },
                          child: Semantics(
                              button: true,
                              label: items[index].$1,
                              selected: selected,
                              child: GestureDetector(
                                onTap: () => _close(items[index].$2),
                                child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                        color: widget.futuristic
                                            ? null
                                            : selected
                                                ? const Color(0xFF40516A)
                                                : const Color(0xFF252B36),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        gradient: widget.futuristic
                                            ? LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: futuristicColors)
                                            : null,
                                        border: Border.all(
                                            color: selected
                                                ? widget.futuristic
                                                    ? FuturisticPalette.pearl
                                                    : const Color(0xFFB9D1EA)
                                                : const Color(0x40FFFFFF),
                                            width: selected ? 2 : 1),
                                        boxShadow: widget.futuristic && selected
                                            ? const [
                                                BoxShadow(
                                                    color: Color(0x408C6BCC),
                                                    blurRadius: 12,
                                                    offset: Offset(0, 4))
                                              ]
                                            : const []),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(items[index].$3,
                                              color: widget.futuristic
                                                  ? selected
                                                      ? FuturisticPalette.pearl
                                                      : FuturisticPalette.accent
                                                  : Colors.white,
                                              size: 28),
                                          const SizedBox(height: 8),
                                          Text(items[index].$1,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: widget.futuristic
                                                      ? FuturisticPalette.pearl
                                                      : Colors.white,
                                                  fontSize: 14)),
                                        ])),
                              )),
                        );
                      },
                    )),
                  ]),
            )),
      ),
    );
    return LauncherPadScope(
        menu: false,
        revealFocus: false,
        onCommand: _command,
        child: Focus(
            skipTraversal: true,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              final command = {
                    LogicalKeyboardKey.enter: '2',
                    LogicalKeyboardKey.numpadEnter: '2',
                    LogicalKeyboardKey.space: '2',
                    LogicalKeyboardKey.gameButtonA: '2',
                    LogicalKeyboardKey.digit2: '2',
                    LogicalKeyboardKey.digit3: '3',
                    LogicalKeyboardKey.backspace: '3',
                    LogicalKeyboardKey.numpadAdd: 'START',
                  }[event.logicalKey] ??
                  (event.character == '+' ? 'START' : null);
              if (command == null) return KeyEventResult.ignored;
              _command(command);
              return KeyEventResult.handled;
            },
            child: !widget.futuristic
                ? dialog
                : GlassBackdrop(
                    animated: false,
                    background:
                        widget.scene == null
                            ? const ColoredBox(color: Color(0xFF090F20))
                            : RawImage(image: widget.scene, fit: BoxFit.cover),
                    child: dialog)));
  }
}
