// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Controllers/Notificacao.dart';

class NotificacaoPop extends StatelessWidget {
  const NotificacaoPop({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Notificacao>(builder: (context, notf, child) {
      return AnimatedContainer(
        duration: const Duration(seconds: 1),
        child: Container(
          width: 350,
          height: 150,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomRight: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                  color: Colors.white24,
                  blurRadius: 12,
                  spreadRadius: 3,
                  offset: Offset(10, 8))
            ],
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 31, 0, 8),
                Color.fromARGB(255, 0, 19, 36),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(notf.ico, color: Colors.white),
              const SizedBox(height: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    notf.mensage, // Mensagem do provedor
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                    textAlign: TextAlign.center, // Alinhamento central
                    overflow: TextOverflow.visible, // Quebra o texto em múltiplas linhas
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
