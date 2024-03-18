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
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        decoration: File(iconInitial.imgStr).existsSync() ?   BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image: FileImage(            
              File(iconInitial.imgStr ,),))
        ) : const BoxDecoration(color: Colors.transparent 
        ),
        height: 200,
        width: 135,
        child: focus ? Center(child: Text(iconInitial.nome,style: const TextStyle(fontSize: 25,color: Colors.white),)) : Container()    ),

    );
  }
}