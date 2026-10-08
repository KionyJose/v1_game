import 'package:flutter/material.dart';
import '../Interface/launcher_pad_scope.dart';

class StartupAccessView extends StatelessWidget {
  const StartupAccessView(
      {super.key, required this.issues, required this.retry});
  final List<String> issues;
  final VoidCallback? retry;

  @override
  Widget build(BuildContext context) => LauncherPadScope(
        menu: false,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
              child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.folder_off_outlined,
                    color: Colors.amber, size: 48),
                const SizedBox(height: 20),
                const Text('Precisamos de acesso à pasta de dados',
                    style: TextStyle(color: Colors.white, fontSize: 26)),
                const SizedBox(height: 20),
                Text(issues.join('\n\n'),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 18)),
                const SizedBox(height: 24),
                FilledButton(
                    autofocus: true,
                    onPressed: retry,
                    child: Text(retry == null
                        ? 'Verificando…'
                        : 'Verificar novamente')),
              ]),
            ),
          )),
        ),
      );
}
