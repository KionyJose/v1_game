import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'download_card.dart';
import 'download_record.dart';
import 'downloads_controller.dart';
import 'pad_navigation.dart';

class DownloadsTela extends StatefulWidget {
  final DownloadsController? controller;
  final bool enablePad;
  const DownloadsTela({super.key, this.controller, this.enablePad = true});
  @override
  State<DownloadsTela> createState() => _DownloadsTelaState();
}

class _DownloadsTelaState extends State<DownloadsTela> {
  late final DownloadsController _controller;
  PadNavigation? _pad;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DownloadsController.instance;
    _controller.initialize().catchError((_) {});
    if (widget.enablePad) {
      _pad = PadNavigation(_padCommand)..start();
    }
  }

  @override
  void dispose() {
    _pad?.dispose();
    super.dispose();
  }

  void _padCommand(PadCommand command) {
    if (!mounted) return;
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (command == PadCommand.back) {
      Navigator.of(context).maybePop();
      return;
    }
    if (focusContext == null) return;
    if (command == PadCommand.select) {
      Actions.maybeInvoke(focusContext, const ActivateIntent());
      return;
    }
    FocusScope.of(focusContext).focusInDirection({
      PadCommand.up: TraversalDirection.up,
      PadCommand.down: TraversalDirection.down,
      PadCommand.left: TraversalDirection.left,
      PadCommand.right: TraversalDirection.right
    }[command]!);
  }

  Future<void> _delete(DownloadRecord item) async {
    bool removePayload = false;
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                  title: Text('Excluir ${item.name}?'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text(
                        'Remove o registro e os arquivos .torrent da pasta de compras.'),
                    CheckboxListTile(
                        value: removePayload,
                        onChanged: (value) =>
                            setDialogState(() => removePayload = value!),
                        title: const Text('Excluir também os arquivos do jogo'),
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
                )));
    if (confirm == true) {
      await _controller.delete(item, deletePayload: removePayload);
    }
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
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
                backgroundColor: const Color(0xFF10121B),
                appBar: AppBar(title: const Text('Downloads'), actions: [
                  IconButton(
                      tooltip: 'Atualizar Downloads',
                      onPressed: _controller.refresh,
                      icon: const Icon(Icons.refresh))
                ]),
                body: SafeArea(
                    child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final items = _controller.items;
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
                                            child: ListView.separated(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 8),
                                              itemCount: items.length,
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(height: 14),
                                              itemBuilder: (_, index) =>
                                                  DownloadCard(
                                                      key: ValueKey(
                                                          items[index].id),
                                                      item: items[index],
                                                      controller: _controller,
                                                      autofocus: index == 0,
                                                      onDelete: () => _delete(
                                                          items[index])),
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
              )));
}
