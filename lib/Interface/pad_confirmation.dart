import 'package:flutter/material.dart';
import 'launcher_pad_scope.dart';

Future<String?> confirmarPad(BuildContext context, String mensagem) {
  bool closed = false;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      void finish(String? answer) {
        if (closed || !dialogContext.mounted) return;
        closed = true;
        Navigator.of(dialogContext).pop(answer);
      }

      return LauncherPadScope(
        menu: false,
        onCommand: (command) {
          if (closed) return true;
          if (command == '3' || command == 'START') {
            finish(null);
            return true;
          }
          return false;
        },
        child: AlertDialog(
          title: const Text('Confirmar ação'),
          content: Text(mensagem),
          actions: [
            OutlinedButton(
              autofocus: true,
              onPressed: () => finish('Nao'),
              child: const Text('Não'),
            ),
            FilledButton(
              onPressed: () => finish('Sim'),
              child: const Text('Sim'),
            ),
          ],
        ),
      );
    },
  );
}
