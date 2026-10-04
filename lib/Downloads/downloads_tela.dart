import '../Interface/launcher_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'download_card.dart';
import 'download_record.dart';
import 'downloads_controller.dart';
import '../Interface/launcher_pad_scope.dart';
import '../Interface/pad_scroll_target.dart';
import '../Bando de Dados/db.dart';
import 'package:path/path.dart' as p;
import 'download_game_launcher.dart';
import 'download_destination.dart';
import 'game_preparation.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../Controllers/JanelaCtrl.dart';

class DownloadsTela extends StatefulWidget {
  final DownloadsController? controller;
  final bool enablePad;
  final Future<void> Function(String)? onLaunchGame;
  final Future<void> Function(String)? onOpenFolder;
  final Future<List<String>> Function()? loadDrives;
  const DownloadsTela(
      {super.key,
      this.controller,
      this.enablePad = true,
      this.onLaunchGame,
      this.onOpenFolder,
      this.loadDrives});
  @override
  State<DownloadsTela> createState() => _DownloadsTelaState();
}

class _DownloadsTelaState extends State<DownloadsTela> with WindowListener {
  late final DownloadsController _controller;
  final _itemFocus = <String, FocusNode>{};
  JanelaCtrl? _gameWindow;
  bool _wasPinned = false;

  void _restoreWindowPin() {
    _gameWindow?.telaPresaReverse(usarEstado: true, estado: _wasPinned);
    _gameWindow = null;
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

  Future<void> _play(DownloadRecord item) async {
    try {
      if (item.state != DownloadState.completed) return;
      if (item.sourceType != ReleaseSource.fitGirl) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Este release ainda não tem protocolo automático de instalação. Abrindo a pasta do download.')));
        if (widget.onOpenFolder != null) {
          await widget.onOpenFolder!(item.destination);
        } else {
          await openDownloadedFolder(item.destination);
        }
        return;
      }
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
      if (widget.onLaunchGame != null) {
        await widget.onLaunchGame!(path);
      } else {
        _gameWindow = Provider.of<JanelaCtrl?>(context, listen: false);
        _wasPinned = _gameWindow?.telaPresa ?? false;
        _gameWindow?.telaPresaReverse(usarEstado: true, estado: false);
        await DB().openFile(path,
            workingDirectory: p.dirname(path), throwOnError: true);
      }
    } catch (_) {
      _restoreWindowPin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(item.sourceType != ReleaseSource.fitGirl
                ? 'Não foi possível abrir a pasta do download. Verifique se ela existe e está acessível.'
                : 'Não foi possível abrir o jogo. Verifique o executável e a instalação.')));
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
                            'Remove o registro e os arquivos .torrent da pasta de compras.'),
                        CheckboxListTile(
                            value: removePayload,
                            onChanged: (value) =>
                                setDialogState(() => removePayload = value!),
                            title: const Text(
                                'Excluir também os arquivos do jogo'),
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
