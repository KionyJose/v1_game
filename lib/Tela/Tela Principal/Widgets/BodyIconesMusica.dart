// ignore_for_file: file_names

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';

class BodyIconesMusica extends StatefulWidget {
  final PrincipalCtrl ctrl;
  final double tamanhoBloco;

  const BodyIconesMusica({
    super.key,
    required this.ctrl,
    required this.tamanhoBloco,
  });

  @override
  State<BodyIconesMusica> createState() => _BodyIconesMusicaState();
}

class _BodyIconesMusicaState extends State<BodyIconesMusica> {
  late ScrollController _localScrollController;
  late int _ultimoPedidoTopo;

  @override
  void initState() {
    super.initState();
    _localScrollController = ScrollController();
    _ultimoPedidoTopo = widget.ctrl.musicaScrollTopRequest;
  }

  @override
  void didUpdateWidget(BodyIconesMusica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_ultimoPedidoTopo == widget.ctrl.musicaScrollTopRequest) return;
    _ultimoPedidoTopo = widget.ctrl.musicaScrollTopRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_localScrollController.hasClients) return;
      _localScrollController.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _localScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: widget.ctrl.focusScopeMusica,
      child: Container(
        margin: const EdgeInsets.only(top: 60, left: 40, bottom: 20, right: 40),
        width: MediaQuery.of(context).size.width + widget.tamanhoBloco * 3,
        alignment: Alignment.center,
        child: GridView.builder(
          padding: const EdgeInsets.all(9),
          controller: _localScrollController,
          itemCount: widget.ctrl.listMusica.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            bool foco = index == widget.ctrl.selectedIndexMusica;
            return _buildMediaButton(index, foco);
          },
        ),
      ),
    );
  }

  Widget _buildMediaButton(int i, bool foco) {
    const sdw = Shadow(blurRadius: 20, color: Colors.black);
    return Focus(
      focusNode: widget.ctrl.focusNodeMusica[i],
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          widget.ctrl.onFocusChangeGrid(i, PrincipalCtrl.musc);
        }
      },
      child: FittedBox(
        child: SizedBox(
          height: 200,
          width: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(widget.ctrl.listMusica[i].imgLocal),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Container(color: Colors.black38),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: foco
                      ? Border.all(
                          color: Colors.white,
                          width: 3,
                        )
                      : null,
                ),
              ),
              if (foco)
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.keyboard_double_arrow_up,
                      shadows: [sdw, sdw],
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
