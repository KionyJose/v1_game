import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Controllers/SonsSistema.dart';
import 'futuristic_material.dart';
import 'launcher_pad_scope.dart';
import 'pad_shortcuts_sheet.dart';

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
  /// A grade: ações sobre o card, na ordem em que se usam.
  ///
  /// Material Icons não tem arma nem espada; `videogame_asset` é o glifo de
  /// jogo mais próximo, e o rótulo carrega o verbo.
  static const items = [
    ('Adicionar jogo', 'Add', Icons.videogame_asset_rounded),
    ('Buscar jogos', 'busca', Icons.search_rounded),
    ('Imagem local', 'Caminho de Imagem', Icons.add_photo_alternate_rounded),
    ('Imagem download', 'Imagem da Download', Icons.image_rounded),
    ('Caminho do jogo', 'Caminho do game', Icons.insert_drive_file_rounded),
    ('Atalhos e dicas', 'Atalhos', Icons.shortcut_rounded),
    ('Interfaces', 'Interfaces', Icons.dashboard_rounded),
    ('Excluir card', 'Excluir Card', Icons.delete_outline_rounded),
  ];

  /// A barra: ações do sistema, que não são sobre o card. Saíram da grade
  /// porque disputavam espaço com o que se usa toda hora.
  static const acoesDaBarra = [
    ('Downloads', 'Downloads', Icons.download_rounded),
    ('Suspender', 'Suspender', Icons.bedtime_rounded),
    ('Configurações', 'Cfg', Icons.settings_rounded),
    ('Fechar', '', Icons.close_rounded),
  ];

  final _nodes = List.generate(items.length, (_) => FocusNode());
  final _nodesDaBarra =
      List.generate(acoesDaBarra.length, (_) => FocusNode());
  final _scroll = ScrollController();
  int _selected = 0;

  /// Qual ícone da barra está apontado, quando o Pad está nela.
  int _selecionadoNaBarra = 0;
  bool _naBarra = false;
  bool _closed = false;
  static const stride = 106.0;

  /// Altura da barra do topo. Os ícones a preenchem inteira, sem margem.
  static const alturaDaBarra = 46.0;

  void _close(String result) {
    if (_closed || !mounted) return;
    _closed = true;
    SonsSistema.click();
    Navigator.of(context).pop(result);
  }

  /// Atalhos é só leitura: abre por cima do Mais em vez de fechá-lo, e ao sair
  /// devolve o foco ao próprio card, de onde a navegação continua.
  Future<void> _activate(int index) async {
    if (_closed) return;
    final action = items[index].$2;
    if (action != 'Atalhos') {
      _close(action);
      return;
    }
    SonsSistema.click();
    await mostrarAtalhosDoPad(context);
    if (!mounted || _closed) return;
    _select(index);
    _nodes[index].requestFocus();
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

  /// Leva o Pad para a barra do topo, ou de volta para a grade.
  void _irParaBarra(bool barra) {
    if (_naBarra == barra) return;
    setState(() => _naBarra = barra);
    SonsSistema.direction();
    (barra ? _nodesDaBarra[_selecionadoNaBarra] : _nodes[_selected])
        .requestFocus();
  }

  void _selecionarNaBarra(int indice) {
    final alvo = indice.clamp(0, acoesDaBarra.length - 1);
    if (alvo == _selecionadoNaBarra && _naBarra) return;
    setState(() {
      _selecionadoNaBarra = alvo;
      _naBarra = true;
    });
    SonsSistema.direction();
    _nodesDaBarra[alvo].requestFocus();
  }

  /// `_close` já toca o som de confirmação; tocar aqui dobraria.
  void _acionarDaBarra(int indice) =>
      _close(acoesDaBarra[indice].$2);

  bool _command(String command) {
    if (_closed) return true;
    if (_naBarra) {
      switch (command) {
        case 'ESQUERDA':
          _selecionarNaBarra(_selecionadoNaBarra - 1);
        case 'DIREITA':
          _selecionarNaBarra(_selecionadoNaBarra + 1);
        case 'BAIXO':
          _irParaBarra(false);
        case '2':
          _acionarDaBarra(_selecionadoNaBarra);
        case '3':
        case 'START':
          _close('');
      }
      return true;
    }
    switch (command) {
      case 'CIMA':
        // Da primeira linha, sobe para a barra em vez de parar.
        _selected >= 2 ? _select(_selected - 2) : _irParaBarra(true);
      case 'BAIXO':
        if (_selected + 2 < items.length) _select(_selected + 2);
      case 'ESQUERDA':
        if (_selected.isOdd) _select(_selected - 1);
      case 'DIREITA':
        if (_selected.isEven && _selected + 1 < items.length) {
          _select(_selected + 1);
        }
      case '2':
        _activate(_selected);
      case '3':
      case 'START':
        _close('');
    }
    return true;
  }

  Widget _panel(Widget child) {
    if (widget.futuristic) {
      return GlassPanel(
          radius: 32,
          appearanceColor: const Color(0xB30A0D19),
          child: child);
    }
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

  /// Um ícone da barra: quadrado, da altura inteira, sem padding.
  Widget _botaoDaBarra(int indice) {
    final acao = acoesDaBarra[indice];
    final apontado = _naBarra && indice == _selecionadoNaBarra;
    return Focus(
      focusNode: _nodesDaBarra[indice],
      onFocusChange: (focado) {
        if (focado) _selecionarNaBarra(indice);
      },
      child: Semantics(
        button: true,
        label: acao.$1,
        selected: apontado,
        child: Tooltip(
          message: acao.$1,
          child: GestureDetector(
            onTap: () => _acionarDaBarra(indice),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: alturaDaBarra,
              height: alturaDaBarra,
              decoration: BoxDecoration(
                color: apontado
                    ? (widget.futuristic
                        ? const Color(0x908063BB)
                        : const Color(0xFF40516A))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: apontado
                        ? (widget.futuristic
                            ? FuturisticPalette.pearl
                            : const Color(0xFFB9D1EA))
                        : Colors.transparent,
                    width: 2),
              ),
              child: Icon(acao.$3,
                  size: 24,
                  color: widget.futuristic
                      ? (apontado
                          ? FuturisticPalette.pearl
                          : FuturisticPalette.accent)
                      : Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in [..._nodes, ..._nodesDaBarra]) {
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
                    SizedBox(
                      height: alturaDaBarra,
                      child: Row(children: [
                        const SizedBox(width: 6),
                        Text('Mais',
                            style: TextStyle(
                                color: widget.futuristic
                                    ? FuturisticPalette.pearl
                                    : Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w500)),
                        const Spacer(),
                        // Sem margem nem respiro: os ícones tomam a altura
                        // inteira da barra, como pedido.
                        for (var i = 0; i < acoesDaBarra.length; i++)
                          _botaoDaBarra(i),
                      ]),
                    ),
                    const SizedBox(height: 18),
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
                                onTap: () => _activate(index),
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
