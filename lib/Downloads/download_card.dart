import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'download_record.dart';
import 'downloads_controller.dart';

String downloadStateLabel(DownloadState state) => const {
      DownloadState.ready: 'Pronto para iniciar',
      DownloadState.preparing: 'Preparando',
      DownloadState.queued: 'Na fila',
      DownloadState.downloading: 'Baixando',
      DownloadState.paused: 'Pausado',
      DownloadState.canceled: 'Cancelado',
      DownloadState.completed: 'Concluído',
      DownloadState.error: 'Erro',
    }[state]!;

String formatDownloadBytes(num bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var index = 0;
  while (value >= 1024 && index < units.length - 1) {
    value /= 1024;
    index++;
  }
  return '${value.toStringAsFixed(index == 0 ? 0 : 1)} ${units[index]}';
}

class DownloadCard extends StatefulWidget {
  final DownloadRecord item;
  final DownloadsController controller;
  final bool autofocus;
  final VoidCallback onDelete;
  const DownloadCard(
      {super.key,
      required this.item,
      required this.controller,
      required this.onDelete,
      this.autofocus = false});
  @override
  State<DownloadCard> createState() => _DownloadCardState();
}

class _DownloadCardState extends State<DownloadCard> {
  final _focus = FocusNode();
  final _start = FocusNode();
  final _pause = FocusNode();
  final _delete = FocusNode();
  bool _focused = false;
  @override
  void dispose() {
    _focus.dispose();
    _start.dispose();
    _pause.dispose();
    _delete.dispose();
    super.dispose();
  }

  void _openActions() {
    if (widget.item.busy) return;
    if (widget.item.running) {
      _pause.requestFocus();
    } else if (widget.item.state != DownloadState.completed) {
      _start.requestFocus();
    } else {
      _delete.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.state == DownloadState.completed
        ? const Color(0xFF6CE4B0)
        : const Color(0xFFA99AFF);
    return Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _openActions();
            return null;
          }),
        },
        child: Focus(
            key: ValueKey('focus-${item.id}'),
            focusNode: _focus,
            autofocus: widget.autofocus,
            onFocusChange: (focused) {
              setState(() => _focused = focused);
              if (focused) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    Scrollable.ensureVisible(context,
                        duration: const Duration(milliseconds: 180),
                        alignment: 0.25);
                  }
                });
              }
            },
            onKeyEvent: (_, event) {
              if (_focus.hasPrimaryFocus &&
                  event is KeyDownEvent &&
                  [
                    LogicalKeyboardKey.enter,
                    LogicalKeyboardKey.space,
                    LogicalKeyboardKey.gameButtonA
                  ].contains(event.logicalKey)) {
                _openActions();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: GestureDetector(
                onTap: _focus.requestFocus,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: _focused
                          ? const Color(0xFF25223C)
                          : const Color(0xFF191D2A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _focused ? color : const Color(0xFF303449),
                          width: _focused ? 2 : 1)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(
                                  item.state == DownloadState.completed
                                      ? Icons.check
                                      : Icons.download,
                                  color: color)),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(item.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(
                                    item.sourceName.isEmpty
                                        ? 'Fonte não informada'
                                        : item.sourceName,
                                    style: const TextStyle(
                                        color: Color(0xFFB9B5D2))),
                              ])),
                          const SizedBox(width: 12),
                          Text('${(item.progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: color,
                                  fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 18),
                        LinearProgressIndicator(
                            value: item.progress,
                            minHeight: 7,
                            borderRadius: BorderRadius.circular(8),
                            color: color,
                            backgroundColor: const Color(0xFF34384A)),
                        const SizedBox(height: 12),
                        Wrap(spacing: 20, runSpacing: 8, children: [
                          Text(downloadStateLabel(item.state),
                              style: TextStyle(color: color)),
                          Text(
                              '${formatDownloadBytes(item.downloadedBytes)} / ${formatDownloadBytes(item.totalBytes)}'),
                          Text('${formatDownloadBytes(item.speedBytes)}/s'),
                          Text('${item.peers} conexões'),
                        ]),
                        if (item.error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(item.error!,
                                  style: const TextStyle(
                                      color: Colors.orangeAccent))),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          alignment: Alignment.topCenter,
                          child: _focused
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                      const Divider(height: 30),
                                      if (item.edition.isNotEmpty)
                                        Text(item.edition),
                                      const SizedBox(height: 6),
                                      Text('Destino: ${item.destination}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                      const SizedBox(height: 16),
                                      Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            FilledButton.icon(
                                                focusNode: _start,
                                                onPressed: item.busy ||
                                                        item.running ||
                                                        item.state ==
                                                            DownloadState
                                                                .completed
                                                    ? null
                                                    : () => widget.controller
                                                        .start(item),
                                                icon: const Icon(
                                                    Icons.play_arrow),
                                                label: Text(item.state ==
                                                        DownloadState.paused
                                                    ? 'Retomar'
                                                    : 'Iniciar')),
                                            OutlinedButton.icon(
                                                focusNode: _pause,
                                                onPressed: item.busy ||
                                                        !item.running
                                                    ? null
                                                    : () => widget.controller
                                                        .pause(item),
                                                icon: const Icon(Icons.pause),
                                                label: const Text('Pausar')),
                                            OutlinedButton.icon(
                                                onPressed: item.busy ||
                                                        item.state ==
                                                            DownloadState
                                                                .completed ||
                                                        item.state ==
                                                            DownloadState
                                                                .canceled
                                                    ? null
                                                    : () => widget.controller
                                                        .cancel(item),
                                                icon: const Icon(Icons.stop),
                                                label: const Text('Cancelar')),
                                            OutlinedButton.icon(
                                                focusNode: _delete,
                                                onPressed: item.busy
                                                    ? null
                                                    : widget.onDelete,
                                                icon: const Icon(
                                                    Icons.delete_outline),
                                                label: const Text('Excluir')),
                                          ]),
                                    ])
                              : const SizedBox(width: double.infinity),
                        ),
                      ]),
                ))));
  }
}
