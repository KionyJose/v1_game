// ignore_for_file: file_names
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Class/Paad.dart';

class ImagemFullScren extends StatelessWidget {
  const ImagemFullScren({required this.urlImg, super.key});
  final String urlImg;

  @override
  Widget build(BuildContext context) {
    return Selector<Paad, String>(
      selector: (context, paad) => paad.click, // Escuta apenas click
      builder: (context, event, child) {
        if(event == "3") Navigator.pop(context);
        return Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.contain,
              image:FileImage(File(urlImg)), //AssetImage('assets/BGICOdefault.png'),
            ),
          ),                    
        );
      },
    );
  }
}