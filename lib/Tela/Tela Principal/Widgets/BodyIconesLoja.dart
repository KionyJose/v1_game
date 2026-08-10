// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';

class BodyIconesLoja extends StatelessWidget {
  final PrincipalCtrl ctrl;
  final double tamanhoBloco;

  const BodyIconesLoja({
    super.key,
    required this.ctrl,
    required this.tamanhoBloco,
  });

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: ctrl.focusScopeLoja,
      child: Container(
        margin: const EdgeInsets.only(top: 72, left: 42, right: 42, bottom: 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: ctrl.listLojas.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final loja = ctrl.listLojas[index];
                  final foco = index == ctrl.selectedIndexLoja;
                  return Focus(
                    focusNode: ctrl.focusNodeLoja[index],
                    onFocusChange: (hasFocus) {
                      if (hasFocus) ctrl.onFocusChangeGrid(index, PrincipalCtrl.loja);
                    },
                    child: GestureDetector(
                      onTap: ctrl.mouseBloqueado ? null : () => ctrl.movLoja("2"),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: foco ? Colors.white : Colors.white.withValues(alpha: 0.12),
                            width: foco ? 2.5 : 1,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              loja.cor.withValues(alpha: foco ? 0.95 : 0.62),
                              const Color(0xFF080812),
                            ],
                          ),
                          boxShadow: foco
                              ? [
                                  BoxShadow(
                                    color: loja.cor.withValues(alpha: 0.55),
                                    blurRadius: 32,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -8,
                              bottom: -12,
                              child: Icon(
                                loja.icone,
                                color: Colors.white.withValues(alpha: 0.18),
                                size: 112,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(loja.icone, color: Colors.white, size: foco ? 40 : 34),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loja.nome,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: foco ? 27 : 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      loja.subtitulo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
