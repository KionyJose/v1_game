import 'package:flutter/material.dart';
import 'launcher_pad_scope.dart';

/// Leitura ampliada de textos, com rolagem pelo controle e uma única ação.
Future<void> mostrarTextoAmpliado(BuildContext context,
    {required String titulo, required String texto}) {
  return showDialog<void>(
    context: context,
    builder: (_) => TextViewerDialog(titulo: titulo, texto: texto),
  );
}

class TextViewerDialog extends StatefulWidget {
  final String titulo;
  final String texto;
  const TextViewerDialog(
      {super.key, required this.titulo, required this.texto});

  @override
  State<TextViewerDialog> createState() => _TextViewerDialogState();
}

class _TextViewerDialogState extends State<TextViewerDialog> {
  final _scroll = ScrollController();
  bool _closed = false;

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  bool _command(String command) {
    if (_closed) return true;
    if (command == '3' || command == 'START' || command == '2') {
      _close();
      return true;
    }
    if (command == 'CIMA' || command == 'BAIXO') {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          (_scroll.offset + (command == 'BAIXO' ? 180 : -180))
              .clamp(0.0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      }
      return true;
    }
    return true;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LauncherPadScope(
        menu: false,
        revealFocus: false,
        onCommand: _command,
        child: Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFB6A8FF)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.titulo,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Flexible(
                    child: Scrollbar(
                      controller: _scroll,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.only(right: 20),
                        child: ExcludeFocus(
                          child: SelectableText(widget.texto,
                              style: const TextStyle(
                                  fontSize: 24,
                                  height: 1.65,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      autofocus: true,
                      onPressed: _close,
                      icon: const Icon(Icons.close),
                      label: const Text('Fechar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
