// ignore_for_file: file_names, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

import '../Class/Paad.dart';
import '../Controllers/Notificacao.dart';
import '../Widgets/NotificacaoPop.dart';
import 'PrincipalPage.dart';

class Begin extends StatelessWidget {
  const Begin({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Notificacao>(builder: (context, notf, child){
      return SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                const PrincipalPage(title: 'V1_Games 007'),
                if (notf.ativo)const Positioned(bottom: 20, right: 20, child: NotificacaoPop()),
                escutaPads(),
                // Tela de log com opacidade
                // Positioned.fill(
                //   child: Container(
                //     color: Colors.black.withOpacity(0.5), // Opacidade
                //     child: Center(
                //       child: ListView.builder(
                //         itemCount: logs.length,
                //         itemBuilder: (context, index) {
                //           return Text(
                //             logs[index],
                //             style: const TextStyle(color: Colors.white, fontSize: 18),
                //           );
                //         },
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        );
      },
    );
  }

  escutaPads(){
    late int total;
    return Selector<Paad, List<Controller>>(
      selector: (context, paad) {
        total = paad.controlesAtivos.length;
        return paad.controlesAtivos; // Escuta apenas click
      },
      builder: (context, valorAtual, child) {
        // Aguardando o próximo frame para chamar o showDialog
        return statusPad(total);
      },
    );
  }

  // escutaNotfy(){
  statusPad(int paad){
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 48,right: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
             Text("Versao 3   ",style: TextStyle(fontSize: 12,color: Colors.yellow.withOpacity(0.4))),
            Text(paad.toString(),style: TextStyle(fontSize: 12,color: paad ==0 ? Colors.red: Colors.white)),
            const SizedBox(width: 5),
            Icon(Icons.sports_esports,color: paad == 0 ? Colors.red: Colors.white),
          ],
        ),
      ),
    );
  }
}