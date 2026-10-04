// ignore_for_file: file_names

import 'package:flutter/material.dart';
import '../../../Interface/launcher_horizontal_list.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';

class BodyIconesJogos extends StatefulWidget {
  final PrincipalCtrl ctrl;
  final double tamanhoBloco;
  final Widget Function(PrincipalCtrl ctrl, int index, double tamanho) cardAnimado;
  final Widget Function(PrincipalCtrl ctrl, int index) cardAnimadoAdd;

  const BodyIconesJogos({
    super.key,
    required this.ctrl,
    required this.tamanhoBloco,
    required this.cardAnimado,
    required this.cardAnimadoAdd,
  });

  @override
  State<BodyIconesJogos> createState() => _BodyIconesJogosState();
}

class _BodyIconesJogosState extends State<BodyIconesJogos> {
  late ScrollController _localScrollController;
  
  @override
  void initState() {
    super.initState();
    // Cria um ScrollController local para este widget
    _localScrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _localScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double telaWidth = MediaQuery.of(context).size.width;
    
    return Stack(
      children: [
        Positioned(
          left: -telaWidth,
          top: 50,
          child: SizedBox(
            height: telaWidth / 4,
            width: (telaWidth * 2) + widget.tamanhoBloco * 1.5,
            child: FocusScope(
              node: widget.ctrl.focusScopeIcones,
              child: LauncherHorizontalList(
                controller: _localScrollController,
                itemCount: widget.ctrl.focusNodeIcones.length,
                itemSize: widget.tamanhoBloco, // Tamanho horizontal
                itemBuilder: (context, i) {
                  bool isFoco = widget.ctrl.selectedIndexIcone == i;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          width: isFoco
                              ? (widget.tamanhoBloco - 26) * 3
                              : (widget.tamanhoBloco - 26), // Largura do item base
                          duration: const Duration(milliseconds: 150),
                          child: FittedBox(
                            child: Focus(
                              focusNode: widget.ctrl.focusNodeIcones[i],
                              onFocusChange: (hasFocus) {
                                if (!mounted) return;
                                if (hasFocus) {
                                  // Move o scroll local ANTES de chamar o método do controller
                                  try {
                                    if (_localScrollController.hasClients) {
                                      _localScrollController.animateTo(
                                        i * widget.tamanhoBloco,
                                        duration: const Duration(milliseconds: 700),
                                        curve: Curves.decelerate,
                                      );
                                    }
                                  } catch (_) {}
                                }
                                // Chama o método original do controller
                                widget.ctrl.onFocusChangeIcones(hasFocus, i,
                                    tamanho: widget.tamanhoBloco);
                              },
                              child: widget.ctrl.listIconsInicial.isEmpty
                                  ? widget.cardAnimadoAdd(widget.ctrl, i)
                                  : widget.cardAnimado(
                                      widget.ctrl, i, widget.tamanhoBloco),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
