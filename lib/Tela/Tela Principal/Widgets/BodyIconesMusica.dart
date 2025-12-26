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

  @override
  void initState() {
    super.initState();
    _localScrollController = ScrollController();
  }

  @override
  void dispose() {
    try {
      if (_localScrollController.hasClients) {
        _localScrollController.jumpTo(_localScrollController.offset);
      }
    } catch (_) {}
    
    try {
      _localScrollController.dispose();
    } catch (_) {}
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
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: FileImage(File(widget.ctrl.listMusica[i].imgLocal)),
            ),
            border: foco
                ? Border.all(
                    color: Colors.white,
                    width: 3,
                  )
                : null,
          ),
          alignment: Alignment.bottomCenter,
          height: 200,
          width: 300,
          child: foco
              ? const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(
                    Icons.keyboard_double_arrow_up,
                    shadows: [sdw, sdw],
                    color: Colors.white,
                  ),
                )
              : Container(),
        ),
      ),
    );
  }
}
