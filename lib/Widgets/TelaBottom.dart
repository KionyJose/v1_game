// ignore_for_file: file_names

import 'package:flutter/material.dart';

class TelaBottom extends StatelessWidget {
  const TelaBottom({super.key});

  void _mostrarBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite expandir o conteúdo
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Ajusta para o teclado
            left: 16, right: 16, top: 16
          ),
          child: SizedBox(
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Insira os dados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const TextField(
                  decoration: InputDecoration(labelText: 'Digite algo'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child:const Text('Fechar'),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:const Text('Bottom Sheet')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _mostrarBottomSheet(context),
          child: const Text('Abrir Pop-up'),
        ),
      ),
    );
  }
}
