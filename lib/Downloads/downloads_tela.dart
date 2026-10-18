import '../Interface/launcher_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'download_card.dart';
import 'download_record.dart';
import 'downloads_controller.dart';
import '../Interface/launcher_pad_scope.dart';
import '../Interface/pad_scroll_target.dart';
import 'download_game_launcher.dart';
import 'download_destination.dart';
import 'game_preparation.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../Controllers/JanelaCtrl.dart';
import '../Class/Paad.dart';
import '../Class/WebScrap.dart';
import '../Tela/SeletorImagens/SeletorImagens.dart';
import '../Widgets/Pops/Pops.dart';
import 'installed_game_library.dart';

class DownloadsTela extends StatefulWidget {
  final DownloadsController? controller;
  final bool enablePad;
  final Future<void> Function(String)? onOpenFolder;
  final Future<List<String>> Function()? loadDrives;

  /// Recebe o nome do jogo e devolve o caminho local da capa escolhida, ou
  /// nulo quando o jogador desiste. Sem isso, usa o seletor da tela principal.
  final Future<String?> Function(String)? chooseCover;
  const DownloadsTela(
      {super.key,
      this.controller,
      this.enablePad = true,
      this.onOpenFolder,
      this.loadDrives,
      this.chooseCover});
  @override
  State<DownloadsTela> createState() => _DownloadsTelaState();
}

class _DownloadsTelaState extends State<DownloadsTela> with WindowListener {
  late final DownloadsController _controller;
  final _itemFocus = <String, FocusNode>{};

  /// Jogos instalados nesta visita à tela que ainda aguardam a escolha da capa.
  final _awaitingCover = <String>{};
  JanelaCtrl? _gameWindow;
  bool _wasPinned = false;

  /// A fixação volta ao estado anterior fora do quadro em curso: `dispose`
  /// roda com a árvore travada, e `telaPresaReverse` notifica o provider do
  /// `JanelaCtrl` — notificar ali derruba o quadro com
  /// "setState() called when widget tree was locked".
  void _restoreWindowPin() {
    final window = _gameWindow;
    if (window == null) return;
    final pinned = _wasPinned;
    _gameWindow = null;
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => window.telaPresaReverse(usarEstado: true, estado: pinned));
    // Fora de um quadro não haveria um próximo para executar o retorno.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void onWindowFocus() => _restoreWindowPin();

  @override
  void dispose() {
    windowManager.removeListener(this);
    _restoreWindowPin();
    for (final node in _itemFocus.values) {
      node.dispose();
    }
    super.dispose();
  }

  bool _moveItem(String id, TraversalDirection direction) {
    if (direction != TraversalDirection.up &&
        direction != TraversalDirection.down) {
      return false;
    }
    final items = _controller.items;
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return true;
    final next = index + (direction == TraversalDirection.down ? 1 : -1);
    if (next >= 0 && next < items.length) {
      _itemFocus[items[next].id]?.requestFocus();
    }
    return true;
  }

  Future<void> _start(DownloadRecord item) async {
    if (item.busy || item.running || item.state == DownloadState.completed) {
      return;
    }
    try {
      if (!item.destinationChosen &&
          item.startedAt == null &&
          item.downloadedBytes == 0 &&
          item.state != DownloadState.paused) {
        final drive = await selectDownloadDrive(context, item.name,
            loadDrives: widget.loadDrives, enablePad: widget.enablePad);
        if (!mounted || drive == null) return;
        await _controller.setDownloadDrive(item, drive);
      }
      if (mounted && _controller.items.contains(item)) {
        await _controller.start(item);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error is StateError
                ? error.message.toString()
                : 'Não foi possível preparar a pasta nesse disco. Escolha um disco com permissão de gravação.')));
      }
    }
  }

  /// Abrir pasta entrega o controle ao Explorer, que não se navega pelo Pad:
  /// a janela deixa de ficar presa à frente e o mouse do sistema é liberado,
  /// como no início de um jogo. Ao voltar o foco ao launcher, `onWindowFocus`
  /// restaura a fixação anterior.
  Future<void> _releaseScreenForMouse() async {
    _gameWindow = Provider.of<JanelaCtrl?>(context, listen: false);
    _wasPinned = _gameWindow?.telaPresa ?? false;
    _gameWindow?.telaPresaReverse(usarEstado: true, estado: false);
    await Provider.of<Paad?>(context, listen: false)
        ?.ativaMouse(usarEstado: true, estado: true);
  }

  Future<void> _openFolder(DownloadRecord item) async {
    try {
      await _releaseScreenForMouse();
      if (!mounted) return;
      if (widget.onOpenFolder != null) {
        await widget.onOpenFolder!(item.destination);
      } else {
        await openDownloadedFolder(item.destination);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Não foi possível abrir a pasta. Verifique se ela existe e está acessível.')));
      }
    }
  }

  /// A capa é gravada na entrada que o cadastro acabou de criar, sem mexer nos
  /// outros jogos do catálogo.
  Future<void> _chooseCover(DownloadRecord item, String executable) async {
    final name = installedGameName(item.name);
    final saved = await (widget.chooseCover ?? _pickCoverImage)(name);
    if (!mounted || saved == null || saved.isEmpty) return;
    await _controller.setInstalledCover(executable, saved);
  }

  /// Mesmo seletor de imagens da tela principal, já baixando a escolha. Aqui
  /// nada é liberado para o mouse: o seletor se navega pelo Pad, e mexer na
  /// fixação da janela ou no mouse do sistema só atrapalharia quem está de
  /// controle na mão.
  Future<String?> _pickCoverImage(String name) async {
    final chosen = await Pops.popTela(context, SeletorImagens(nome: name));
    if (!mounted || chosen is! String || chosen.isEmpty) return null;
    final saved = await WebScrap.downloadImage(chosen, name);
    if (!mounted) return null;
    if (saved.startsWith('Erro::')) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(saved.replaceFirst('Erro:: ', ''))));
      return null;
    }
    return saved;
  }

  Future<void> _play(DownloadRecord item) async {
    try {
      if (item.state != DownloadState.completed) return;
      // Sem protocolo automático o cartão não oferece Jogar; o aviso fica nele
      // e a pasta é aberta pelo próprio botão Abrir pasta.
      if (item.sourceType != ReleaseSource.fitGirl) {
        await _openFolder(item);
        return;
      }
      final wasReady =
          item.installationState == 'ready' && item.launchPath != null;
      String? path;
      try {
        path = await _controller.prepareForPlay(item);
      } on PreparationCanceled {
        return;
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(item.installationError ??
                'Não foi possível concluir a instalação automática. Selecione um executável já instalado.')));
      }
      if (path == null) {
        if (!mounted) return;
        path = await selectDownloadedGame(context, item.destination,
            enablePad: widget.enablePad);
        if (path == null || !mounted) return;
        await _controller.registerInstalledGame(item, path);
      }
      if (!mounted) return;
      // Descompactou agora: o jogo não abre nesta vez, para que o Jogar
      // seguinte cuide da capa antes de iniciar.
      if (!wasReady) {
        setState(() => _awaitingCover.add(item.id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Instalação concluída. Toque em Jogar de novo para escolher a capa e abrir o jogo.')));
        return;
      }
      // Sem capa própria o jogo não vai para a biblioteca: ele entraria no
      // início sem identidade. A capa é pedida aqui, e só então ele segue.
      if (!await _controller.hasInstalledCover(path)) {
        if (!mounted) return;
        await _chooseCover(item, path);
        if (!mounted) return;
        if (!await _controller.hasInstalledCover(path)) {
          if (!mounted) return;
          setState(() => _awaitingCover.add(item.id));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'O jogo vai para a biblioteca depois de escolher a capa. Toque em Jogar para escolher.')));
          return;
        }
        if (!mounted) return;
        setState(() => _awaitingCover.remove(item.id));
      }
      if (!mounted) return;
      // A fila não abre o jogo. O cadastro já aconteceu em `prepareForPlay`,
      // que coloca o jogo no primeiro card da biblioteca; aqui a tela só se
      // fecha. Ao voltar, a tela principal recarrega a lista já no primeiro
      // item, com o play nas mãos do jogador.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Jogo pronto no primeiro card da biblioteca. É só dar play.')));
      Navigator.of(context).maybePop();
    } catch (_) {
      _restoreWindowPin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(item.sourceType != ReleaseSource.fitGirl
                ? 'Não foi possível abrir a pasta do download. Verifique se ela existe e está acessível.'
                : 'Não foi possível deixar o jogo pronto. Verifique o executável e a instalação.')));
      }
    }
  }

  Future<void> _installSilently(DownloadRecord item) async {
    try {
      final path = await _controller.installSilently(item);
      if (!mounted) return;
      if (path == null) {
        final selected = await selectDownloadedGame(
            context, item.installationDirectory ?? item.destination,
            enablePad: widget.enablePad);
        if (selected == null || !mounted) return;
        await _controller.registerInstalledGame(item, selected);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Instalação silenciosa verificada e cadastrada. Use Jogar para abrir.')));
      }
    } on PreparationCanceled {
      return;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(item.installationError ?? error.toString())));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _controller = widget.controller ?? DownloadsController.instance;
    _controller.initialize().catchError((_) {});
  }

  Future<void> _delete(DownloadRecord item) async {
    bool removePayload = false;
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => LauncherPadScope(
            menu: false,
            enabled: widget.enablePad,
            child: StatefulBuilder(
                builder: (context, setDialogState) => AlertDialog(
                      title: Text('Excluir ${item.name}?'),
                      content:
                          Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text(
                            'Remove o registro, os .torrent da pasta de compras e os arquivos '
                            'do download: o repack, a conferência e as ferramentas de instalação. '
                            'O jogo já instalado continua na sua biblioteca.'),
                        CheckboxListTile(
                            value: removePayload,
                            onChanged: (value) =>
                                setDialogState(() => removePayload = value!),
                            title: const Text(
                                'Excluir também o jogo instalado'),
                            subtitle: const Text(
                                'Apaga a pasta inteira, incluindo o jogo.'),
                            controlAffinity: ListTileControlAffinity.leading),
                      ]),
                      actions: [
                        TextButton(
                            autofocus: true,
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Voltar')),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Excluir'))
                      ],
                    ))));
    if (confirm == true) {
      final before = _controller.items;
      final index = before.indexOf(item);
      await _controller.delete(item, deletePayload: removePayload);
      if (mounted &&
          !_controller.items.contains(item) &&
          _controller.items.isNotEmpty) {
        final remaining = _controller.items;
        _itemFocus[remaining[index.clamp(0, remaining.length - 1)].id]
            ?.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) => LauncherPadScope(
      enabled: widget.enablePad,
      child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.gameButtonB): DismissIntent(),
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: Actions(
              actions: {
                DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) {
                  Navigator.of(context).maybePop();
                  return null;
                })
              },
              child: Scaffold(
                backgroundColor: const Color(0xFF000000),
                appBar: const LauncherHeader(title: Text('Downloads')),
                body: SafeArea(
                    child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final items = _controller.items;
                          for (final item in items) {
                            _itemFocus.putIfAbsent(item.id, () => FocusNode());
                          }
                          return Column(children: [
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 12, 24, 18),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Sua fila de jogos',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium),
                                      const SizedBox(height: 10),
                                      Text(
                                          '${items.where((r) => r.running).length} em andamento  •  '
                                          '${items.where((r) => r.state == DownloadState.completed).length} concluídos  •  ${items.length} downloads'),
                                      if (_controller.error != null)
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 10),
                                            child: Text(_controller.error!,
                                                style: const TextStyle(
                                                    color:
                                                        Colors.orangeAccent))),
                                    ])),
                            Expanded(
                                child: _controller.loading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : items.isEmpty
                                        ? Center(
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(24),
                                                child: Text(
                                                    'Seus torrents comprados aparecerão aqui.\n${_controller.purchaseDirectory}',
                                                    textAlign:
                                                        TextAlign.center)))
                                        : FocusTraversalGroup(
                                            policy:
                                                ReadingOrderTraversalPolicy(),
                                            child: SingleChildScrollView(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 8),
                                              child: Column(children: [
                                                for (var index = 0;
                                                    index < items.length;
                                                    index++) ...[
                                                  if (index > 0)
                                                    const SizedBox(height: 14),
                                                  PadScrollTarget(
                                                      settleDelay: const Duration(
                                                          milliseconds: 200),
                                                      child: DownloadCard(
                                                          key: ValueKey(
                                                              items[index].id),
                                                          item: items[index],
                                                          controller:
                                                              _controller,
                                                          focusNode: _itemFocus[
                                                              items[index].id],
                                                          onVertical: (direction) => _moveItem(
                                                              items[index].id,
                                                              direction),
                                                          onPlay: () => _play(
                                                              items[index]),
                                                          onSilentInstall: () =>
                                                              _installSilently(
                                                                  items[index]),
                                                          onStart: () => _start(
                                                              items[index]),
                                                          onOpenFolder: () =>
                                                              _openFolder(
                                                                  items[index]),
                                                          awaitingCover:
                                                              _awaitingCover
                                                                  .contains(
                                                                      items[index]
                                                                          .id),
                                                          autofocus: index == 0,
                                                          onDelete: () =>
                                                              _delete(items[index]))),
                                                ]
                                              ]),
                                            ))),
                            const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                    'D-pad / analógico: navegar    A / Enter: selecionar    B / Esc: voltar',
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(color: Color(0xFFACA8C7)))),
                          ]);
                        })),
              ))));
}
