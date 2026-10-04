import 'package:flutter/material.dart';
import '../Downloads/downloads_tela.dart';
import '../Tela/Tela loja/scrap_loja.dart';
import 'launcher_pad_scope.dart';
import 'launcher_routes.dart';

Future<void> mostrarMenuLauncher(BuildContext context) async {
  final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => LauncherPadScope(
          menu: false,
          child: AlertDialog(
              title: const Text('Menu do launcher'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                        autofocus: true,
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Downloads'),
                        onPressed: () =>
                            Navigator.pop(dialogContext, 'downloads')),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                        icon: const Icon(Icons.storefront_rounded),
                        label: const Text('Loja Interna'),
                        onPressed: () => Navigator.pop(dialogContext, 'loja')),
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Voltar')),
                  ]))));
  if (!context.mounted) return;
  if (result == 'downloads') {
    await abrirTelaLauncher<void>(context, const DownloadsTela());
  } else if (result == 'loja') {
    await abrirTelaLauncher<void>(context, const ScrapLoja());
  }
}
