import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Bando de Dados/db.dart';
import '../Class/Paad.dart';
import '../Controllers/JanelaCtrl.dart';
import '../Controllers/launcher_window_controller.dart';

/// Controles de janela compartilhados pelos modos Fat e Slim.
class LauncherWindowControls extends StatelessWidget {
  const LauncherWindowControls({super.key, this.slim = false});

  final bool slim;

  @override
  Widget build(BuildContext context) => Consumer2<JanelaCtrl, Paad>(
        builder: (context, janela, pad, _) {
          final count = pad.controlesAtivos.length;
          final scale = slim ? LauncherWindowController.slimScale : 1.0;
          return Align(
            alignment: slim ? Alignment.bottomRight : Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(
                  right: 6 * scale,
                  top: slim ? 0 : 6,
                  bottom: slim ? 4 * scale : 0),
              child: ExcludeFocus(
                child: SizedBox(
                  height: slim
                      ? 36 * scale
                      : MediaQuery.sizeOf(context).height * .054,
                  child: FittedBox(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: slim ? Colors.black : Colors.black54,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: janela.telaPresa
                                ? 'Liberar tela'
                                : 'Travar tela',
                            child: Switch(
                              padding: EdgeInsets.zero,
                              value: janela.telaPresa,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.green,
                              activeTrackColor: Colors.red,
                              thumbIcon: WidgetStatePropertyAll(Icon(
                                janela.telaPresa ? Icons.lock : Icons.lock_open,
                                color: Colors.black,
                              )),
                              onChanged: (_) => janela.telaPresaReverse(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (!slim)
                            const Text('Versao 5   ',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.yellow)),
                          if (count == 0)
                            const Tooltip(
                                message: 'Nenhum controle conectado',
                                child: Icon(Icons.sports_esports,
                                    color: Colors.red)),
                          for (var index = 0; index < count; index++)
                            const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Tooltip(
                                    message: 'Controle conectado',
                                    child: Icon(Icons.sports_esports,
                                        color: Colors.white))),
                          const SizedBox(width: 10),
                          IconButton(
                            tooltip: 'Fechar aplicativo',
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              DB.closeOpenedFileFast();
                              JanelaCtrl.fecharAppForcado(
                                  origem: 'botao interno');
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
