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
    double tamanhoW = MediaQuery.of(context).size.width;
    bool imgFundo = iconInitial.imgStr.isNotEmpty;

    return AnimatedContainer(
        width: focus ? tamanhoW * 0.22 : tamanhoW * 0.08,
        height: focus ? tamanhoW * 0.36 : tamanhoW * 0.08,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if(focus)BoxShadow( color: Colors.pink, offset: const Offset(-2, 0), blurRadius: focus ? 20 : 10),
            if(focus)BoxShadow( color: Colors.blue, offset: const Offset(2, 0), blurRadius: focus ? 20 : 10),
          ],
        ),
        duration: const Duration(milliseconds: 100),
        child: AnimatedOpacity(
          opacity: focus ? 1.0 : 0.95,
          duration: focus ?  const Duration(milliseconds: 350) :  const Duration(seconds: 1),
          child: Container(
            decoration: imgFundo ? deco1() : deco2,
            child: focus ?  texto() : Container(),
          ),
        ),
      
    );
  }
  deco1(){
    return BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      image: DecorationImage(
        fit: BoxFit.cover,
        image: FileImage(File(iconInitial.imgStr)),
      ),
    );
  }
  BoxDecoration deco2 =  BoxDecoration(    
      borderRadius: BorderRadius.circular(30),
      image: const DecorationImage(
        fit: BoxFit.cover,
        image: AssetImage('assets/BGICOdefault.png'),
        scale: 5,
      ),
    );
  
  Widget texto() {
    return Column(
                mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Padding(
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
                  ),Shadow(
                    color: Colors.black,
                    blurRadius: 10,
                  ),Shadow(
                    color: Colors.black,
                    blurRadius: 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
