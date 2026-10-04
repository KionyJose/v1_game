import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'download_record.dart';
import 'downloads_controller.dart';
import 'download_progress_bar.dart';
import '../Interface/pad_direction_intent.dart';

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
  final Future<void> Function() onDelete;
  final Future<void> Function()? onPlay;
  final Future<void> Function()? onStart;
  final FocusNode? focusNode;
  final bool Function(TraversalDirection)? onVertical;
  const DownloadCard(
      {super.key,
      required this.item,
      required this.controller,
      required this.onDelete,
      this.onPlay,
      this.onStart,
      this.focusNode,
      this.onVertical,
      this.autofocus = false});
  @override
  State<DownloadCard> createState() => _DownloadCardState();
}

class _DownloadCardState extends State<DownloadCard> {
  late final FocusNode _focus;
  final _start = FocusNode();
  final _pause = FocusNode();
  final _delete = FocusNode();
  final _cancel = FocusNode();
  final _play = FocusNode();
  bool _playing = false;
  bool _starting = false;
  bool _focused = false;
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    _start.dispose();
    _pause.dispose();
    _delete.dispose();
    _cancel.dispose();
    _play.dispose();
    super.dispose();
  }

  void _openActions() {
    if (widget.item.busy) return;
    if (widget.item.running) {
      _pause.requestFocus();
    } else if (widget.item.state != DownloadState.completed) {
      _start.requestFocus();
    } else {
      _play.requestFocus();
    }
  }

  Future<void> _confirmDelete() async {
    setState(() => _confirming = true);
    await widget.onDelete();
    if (!mounted) return;
    _delete.requestFocus();
    setState(() => _confirming = false);
  }

  Future<void> _playGame() async {
    setState(() => _playing = true);
    try {
      await widget.onPlay?.call();
    } finally {
      if (mounted) {
        setState(() => _playing = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _play.requestFocus();
        });
      }
    }
  }

  Future<void> _startDownload() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      if (widget.onStart != null) {
        await widget.onStart!();
      } else {
        await widget.controller.start(widget.item);
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (widget.item.running) {
              _focus.requestFocus();
            } else {
              _start.requestFocus();
            }
          }
        });
      }
    }
  }

  ButtonStyle get _actionStyle => ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size(160, 48)),
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.focused) &&
                    !states.contains(WidgetState.disabled)
                ? const Color(0xFF7C4DFF)
                : Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.disabled)
                ? const Color(0xFF777777)
                : Colors.white),
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
            color: states.contains(WidgetState.focused)
                ? const Color(0xFFB6A8FF)
                : const Color(0xFF444444))),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );

  bool _moveActions(TraversalDirection direction) {
    if (direction != TraversalDirection.left &&
        direction != TraversalDirection.right) {
      return widget.onVertical?.call(direction) ?? false;
    }
    final item = widget.item;
    if (item.busy) return true;
    final nodes = [
      if (item.state == DownloadState.completed) _play,
      if (!item.running && item.state != DownloadState.completed) _start,
      if (item.running) _pause,
      if (item.state != DownloadState.completed &&
          item.state != DownloadState.canceled)
        _cancel,
      _delete,
    ];
    final current = nodes.indexWhere((node) => node.hasFocus);
    final next = current < 0
        ? 0
        : (current + (direction == TraversalDirection.right ? 1 : -1)) %
            nodes.length;
    nodes[next].requestFocus();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.state == DownloadState.completed
        ? const Color(0xFF6CE4B0)
        : const Color(0xFFA99AFF);
    return Actions(
        actions: {
          PadDirectionIntent: CallbackAction<PadDirectionIntent>(
              onInvoke: (intent) => _moveActions(intent.direction)),
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            _openActions();
            return null;
          }),
        },
        child: Focus(
            key: ValueKey('focus-${item.id}'),
            focusNode: _focus,
            // Com as ações abertas, o cartão não compete com seus botões pelo direcional.
            skipTraversal: _focused,
            autofocus: widget.autofocus,
            onFocusChange: (focused) {
              setState(() => _focused = focused);
            },
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent || event is KeyRepeatEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                    event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  if (_moveActions(
                      event.logicalKey == LogicalKeyboardKey.arrowUp
                          ? TraversalDirection.up
                          : TraversalDirection.down)) {
                    return KeyEventResult.handled;
                  }
                }
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                    event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  _moveActions(event.logicalKey == LogicalKeyboardKey.arrowLeft
                      ? TraversalDirection.left
                      : TraversalDirection.right);
                  return KeyEventResult.handled;
                }
              }
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
                          ? const Color(0xFF202020)
                          : const Color(0xFF131313),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _focused ? color : const Color(0xFF363636),
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
                          Text(
                              item.waitingForData
                                  ? '…'
                                  : '${(item.progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: color,
                                  fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 18),
                        DownloadProgressBar(item: item, color: color),
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
                          child: _focused ||
                                  _confirming ||
                                  _playing ||
                                  _starting
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
                                            if (item.state ==
                                                DownloadState.completed)
                                              FilledButton.icon(
                                                  style: _actionStyle,
                                                  focusNode: _play,
                                                  onPressed:
                                                      item.busy || _playing
                                                          ? null
                                                          : _playGame,
                                                  icon: const Icon(
                                                      Icons.sports_esports),
                                                  label: Text(_playing
                                                      ? 'Abrindo…'
                                                      : 'Jogar')),
                                            if (item.state !=
                                                DownloadState.completed)
                                              FilledButton.icon(
                                                  style: _actionStyle,
                                                  focusNode: _start,
                                                  onPressed: item.busy ||
                                                          _starting ||
                                                          item.running ||
                                                          item.state ==
                                                              DownloadState
                                                                  .completed
                                                      ? null
                                                      : _startDownload,
                                                  icon: const Icon(
                                                      Icons.play_arrow),
                                                  label: Text(item.state ==
                                                          DownloadState.paused
                                                      ? 'Retomar'
                                                      : 'Iniciar')),
                                            if (item.state !=
                                                DownloadState.completed)
                                              FilledButton.icon(
                                                  style: _actionStyle,
                                                  focusNode: _pause,
                                                  onPressed: item.busy ||
                                                          !item.running
                                                      ? null
                                                      : () => widget.controller
                                                          .pause(item),
                                                  icon: const Icon(Icons.pause),
                                                  label: const Text('Pausar')),
                                            if (item.state !=
                                                DownloadState.completed)
                                              FilledButton.icon(
                                                  style: _actionStyle,
                                                  focusNode: _cancel,
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
                                                  label:
                                                      const Text('Cancelar')),
                                            FilledButton.icon(
                                                style: _actionStyle,
                                                focusNode: _delete,
                                                onPressed: item.busy
                                                    ? null
                                                    : _confirmDelete,
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
