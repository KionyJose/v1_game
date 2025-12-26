// ignore_for_file: file_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';

class BodyIconesJogosGrid extends StatefulWidget {
  final PrincipalCtrl ctrl;
  final double tamanhoBloco;

  const BodyIconesJogosGrid({
    super.key,
    required this.ctrl,
    required this.tamanhoBloco,
  });

  @override
  State<BodyIconesJogosGrid> createState() => _BodyIconesJogosGridState();
}

class _BodyIconesJogosGridState extends State<BodyIconesJogosGrid> {
  @override
  Widget build(BuildContext context) {
    const crossCount = 6;
    
    return FocusScope(
      node: widget.ctrl.focusScopeIcones,
      child: Container(
        margin: const EdgeInsets.only(top: 60, left: 40, bottom: 20, right: 40),
        width: MediaQuery.of(context).size.width + widget.tamanhoBloco * 3,
        alignment: Alignment.center,
        child: GridView.builder(
          padding: const EdgeInsets.all(9),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 14 / 9,
          ),
          itemCount: widget.ctrl.listIconsInicial.length,
          itemBuilder: (context, index) {
            final foco = index == widget.ctrl.selectedIndexIcone;
            final item = widget.ctrl.listIconsInicial[index];
            
            return Focus(
              focusNode: widget.ctrl.focusNodeIcones[index],
              onFocusChange: (hasFocus) {
                widget.ctrl.onFocusChangeIcones(hasFocus, index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 14 / 9,
                        child: item.imgStr.isNotEmpty && File(item.imgStr).existsSync()
                            ? Image.file(File(item.imgStr), fit: BoxFit.cover)
                            : Container(color: Colors.black12),
                      ),
                    ),
                    // Sombra / destaque inferior com título centralizado
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black87.withValues(alpha: 0.9),
                              Colors.black45.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.nome,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: foco ? 16 : 12,
                              fontWeight: foco ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Borda de foco
                    if (foco)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
