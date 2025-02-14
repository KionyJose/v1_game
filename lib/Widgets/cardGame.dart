// ignore_for_file: file_names, must_be_immutable

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';

class CardGame extends StatelessWidget {
  late IconInicial iconInitial;
  late bool focus;

  CardGame({super.key, required this.iconInitial, required this.focus});

  @override
  Widget build(BuildContext context) {
    bool imgFundo = iconInitial.imgStr.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: imgFundo
            ? BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: FileImage(File(iconInitial.imgStr)),
                ),
              )
            : const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/BGICOdefault.png'),
                  scale: 5,
                ),
              ),
        child: focus
            ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(child: texto()),  // Envolvendo o texto com Flexible
                ],
              )
            : Container(),
      ),
    );
  }

  Widget texto() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      child: Text(
        iconInitial.nome,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 25,
          color: Colors.white,
          shadows: [
             Shadow(
              color: Colors.black,
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
      ),
    );
  }
}
