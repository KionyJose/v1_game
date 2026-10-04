import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Class/Paad.dart';
import '../Controllers/JanelaCtrl.dart';
import '../Bando de Dados/db.dart';

/// Cabeçalho discreto, integrado ao fundo do launcher.
class LauncherHeader extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  const LauncherHeader({super.key, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final janela = context.watch<JanelaCtrl?>();
    final pads = context.watch<Paad?>()?.controlesAtivos.length ?? 0;
    return ExcludeFocus(
        child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(children: [
          Expanded(
              child: DefaultTextStyle(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge!,
                  child: title ?? const SizedBox.shrink())),
          const SizedBox(width: 12),
          Tooltip(
              message: 'Travar tela',
              child: Switch(
                  value: janela?.telaPresa ?? false,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.green,
                  activeTrackColor: Colors.red,
                  thumbIcon: WidgetStateProperty.all(
                      const Icon(Icons.lock, color: Colors.black)),
                  onChanged: janela == null
                      ? null
                      : (_) => janela.telaPresaReverse())),
          const SizedBox(width: 12),
          Tooltip(
              message: '$pads Pad(s) conectado(s)',
              child: Row(children: [
                for (var i = 0; i < (pads == 0 ? 1 : pads); i++)
                  Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.sports_esports,
                          color: pads == 0 ? Colors.red : Colors.white)),
              ])),
          IconButton(
              tooltip: 'Fechar aplicativo',
              icon: const Icon(Icons.close),
              onPressed: () {
                DB.closeOpenedFileFast();
                JanelaCtrl.fecharAppForcado(origem: 'cabeçalho interno');
              }),
        ]),
      ),
    ));
  }
}
