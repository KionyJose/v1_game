import 'package:flutter/material.dart';
import 'launcher_pad_scope.dart';

/// Mapa de atalhos do controle, aberto por cima de quem chamou. Sai com B, A,
/// Start, Esc, clique fora ou pelo botão; o foco volta para a origem.
Future<void> mostrarAtalhosDoPad(BuildContext context) => showDialog<void>(
      context: context,
      barrierColor: const Color(0xCC05070E),
      builder: (_) => const PadShortcutsSheet(),
    );

class PadShortcutsSheet extends StatefulWidget {
  const PadShortcutsSheet({super.key});

  @override
  State<PadShortcutsSheet> createState() => _PadShortcutsSheetState();
}

class _PadShortcutsSheetState extends State<PadShortcutsSheet> {
  bool _closed = false;

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  /// A folha é só leitura: todo comando do Pad sai dela, e nenhum vaza para o
  /// menu que ficou atrás.
  bool _command(String command) {
    if (_closed) return true;
    if (command == '3' || command == '2' || command == 'START') _close();
    return true;
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
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset('assets/tutorial.png',
                          fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text('B / Esc: voltar ao Mais',
                            style: TextStyle(color: Color(0xFFACA8C7))),
                      ),
                      OutlinedButton.icon(
                        autofocus: true,
                        onPressed: _close,
                        icon: const Icon(Icons.close),
                        label: const Text('Fechar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
