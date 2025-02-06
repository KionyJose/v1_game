// ignore_for_file: must_be_immutable, file_names
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';

class CardGame extends StatelessWidget {
  late IconInicial iconInitial;
  late bool focus;
  CardGame({super.key,required this.iconInitial,required this.focus});
  @override
  Widget build(BuildContext context) {
    bool imgFundo = iconInitial.imgStr != "";
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: imgFundo ?   BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: FileImage(            
              File(iconInitial.imgStr ,),))
        ) :  BoxDecoration(
                image: DecorationImage( fit: BoxFit.cover, image: FileImage(
                  File('assets/BGICOdefault.png'),
                  
                  scale: 5,
                ),
                //Image.asset('assets/BGdefault.jpeg',fit: BoxFit.cover),),
              ),
        ),
        height: 200,
        width: 135,
        child: focus ? Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [texto()],
        ) : Container()
      ),

    );
  }

  texto(){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7 ,horizontal: 10),
      child: Text(
      iconInitial.nome,
      textAlign: TextAlign.center,
      style:  TextStyle(
        fontSize: 25,
        color: Colors.white,
        shadows: [
          for(int i =0; i < 10; i++)
          const Shadow(
            color: Colors.black,
            blurRadius: 30,
            offset: Offset(0,18),
          ),
        ]
      ),
    ),);
  }
}