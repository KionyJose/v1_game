import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Class/Paad.dart';
import '../Controllers/JanelaCtrl.dart';
import '../Bando de Dados/db.dart';
import 'futuristic_material.dart';

class FuturisticHeaderControls extends StatelessWidget {
  const FuturisticHeaderControls(
      {super.key,
      required this.onMenu,
      this.windowControls = const FuturisticWindowControls()});
  final VoidCallback? onMenu;
  final Widget? windowControls;
  @override
  Widget build(BuildContext context) => ExcludeFocus(
      child: GlassPanel(
          radius: 26,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    tooltip: 'Menu',
                    onPressed: onMenu,
                    icon: const Icon(Icons.settings_rounded,
                        color: FuturisticPalette.pearl)),
                if (windowControls != null) windowControls!,
              ]))));
}

class FuturisticWindowControls extends StatelessWidget {
  const FuturisticWindowControls({super.key});
  @override
  Widget build(BuildContext context) {
    final window = context.watch<JanelaCtrl?>();
    final pads = context.watch<Paad?>()?.controlesAtivos.length ?? 0;
    return ExcludeFocus(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
          tooltip: window?.telaPresa == true ? 'Destravar tela' : 'Travar tela',
          icon: Icon(
              window?.telaPresa == true
                  ? Icons.lock_outline
                  : Icons.lock_open_rounded,
              color: window?.telaPresa == true
                  ? Colors.redAccent
                  : Colors.greenAccent,
              size: 18),
          onPressed: window?.telaPresaReverse),
      const SizedBox(width: 8),
      Tooltip(
          message: '$pads controles conectados',
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.sports_esports_rounded,
                color: FuturisticPalette.water, size: 18),
            const SizedBox(width: 6),
            Text('$pads',
                style: const TextStyle(
                    color: FuturisticPalette.pearl, fontSize: 12)),
          ])),
      IconButton(
          tooltip: 'Fechar aplicativo',
          icon: const Icon(Icons.close_rounded,
              color: Color(0xFFB6DDDB), size: 20),
          onPressed: () {
            DB.closeOpenedFileFast();
            JanelaCtrl.fecharAppForcado(origem: 'modo Futurista');
          }),
    ]));
  }
}
