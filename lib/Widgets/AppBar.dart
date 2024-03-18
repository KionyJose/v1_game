// ignore_for_file: file_names

import 'package:flutter/material.dart';

class AppBar extends StatelessWidget {
  const AppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        
        const Center(child:Text("Conectado")
        ),
        IconButton(onPressed: (){}, icon: const Icon(Icons.ac_unit)),
      ],
    );
  }
}