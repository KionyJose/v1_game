// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';

class CardInfWidget extends StatelessWidget {
  final PrincipalCtrl ctrl;

  const CardInfWidget({
    super.key,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: ctrl.focusScopeCardInf,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Focus(
              focusNode: ctrl.focusNodeCardInf[0],
              onFocusChange: (hasFocus) => ctrl.onFocusChangeCardInf(hasFocus, 0),
              child: _buildButton(
                foco: ctrl.selectedIndexCardInfo == 0,
                icone: Icons.play_arrow,
                texto: 'JOGAR',
              ),
            ),
            const SizedBox(width: 20),
            Focus(
              focusNode: ctrl.focusNodeCardInf[1],
              onFocusChange: (hasFocus) => ctrl.onFocusChangeCardInf(hasFocus, 1),
              child: _buildButton(
                foco: ctrl.selectedIndexCardInfo == 1,
                icone: Icons.close,
                texto: 'FECHAR',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required bool foco,
    required IconData icone,
    required String texto,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: !foco
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 50),
                ),
              ],
        border: !foco ? null : Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black12, Colors.blueGrey],
        ),
      ),
      height: 100,
      width: 160,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, color: Colors.white, size: 40),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
