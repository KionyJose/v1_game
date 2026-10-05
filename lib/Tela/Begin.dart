// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';

import '../Controllers/Notificacao.dart';
import '../Widgets/NotificacaoPop.dart';
import 'Tela Principal/PrincipalPage.dart';
import '../Controllers/slim_mode_config_controller.dart';
import '../Widgets/launcher_window_controls.dart';

class Begin extends StatelessWidget {
  const Begin({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Notificacao, JanelaCtrl>(
      builder: (context, notf, janela, child) {
        return SafeArea(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                const PrincipalPage(title: 'V1_Games 001'),
                if (notf.ativo)
                  const Positioned(
                      bottom: 20, right: 20, child: NotificacaoPop()),
                ValueListenableBuilder<bool>(
                  valueListenable: SlimModeConfigController.active,
                  builder: (_, slim, __) => LauncherWindowControls(slim: slim),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
