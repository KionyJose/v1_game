// ignore_for_file: file_names, deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

import '../Class/Paad.dart';
import '../Controllers/Notificacao.dart';
import '../Widgets/NotificacaoPop.dart';
import 'PrincipalPage.dart';

class Begin extends StatelessWidget {
  const Begin({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<Notificacao,JanelaCtrl>(builder: (context, notf,janela, child){
      return SafeArea(
          child: Scaffold(
            body: Stack(
              children: [
                const PrincipalPage(title: 'V1_Games 001'),
                if (notf.ativo)const Positioned(bottom: 20, right: 20, child: NotificacaoPop()),
                escutaPads(),
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
        return statusPad(context, total);
      },
    );
  }

  // escutaNotfy(){
  statusPad(BuildContext ctx, int paad){
    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.054,
        child: FittedBox(
          child: Container(
            margin: const EdgeInsets.only(top: 6,right: 6),
            padding: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(15)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                btnPrenderTela(),
                const SizedBox(width: 20),
                Text("Versao 5   ",style: TextStyle(fontSize: 12,color: Colors.yellow.withOpacity(0.4))),
                if(paad == 0) Icon(Icons.sports_esports,color: paad == 0 ? Colors.red: Colors.white),
                for(int i = 0; i < paad;i++)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.sports_esports,color: Colors.white),
                ),
                // Text(paad.toString(),style: TextStyle(fontSize: 12,color: paad ==0 ? Colors.red: Colors.white)),
                const SizedBox(width: 5),
                const SizedBox(width: 10),
                btnFechaApp(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  btnFechaApp(){
    return MaterialButton(
      padding: EdgeInsets.zero,
      minWidth: 10,
      onPressed: () => exit(0),
      child: const Icon(Icons.close,color: Colors.white)
    );
  }
  btnPrenderTela(){

    return Selector<JanelaCtrl, bool>(
      selector: (context, jnl) => jnl.telaPresa,
      builder: (context, preso, child) {
        return Transform.scale(
          scale: 1.25, // Ajuste a escala conforme desejado(
          child: Switch(
            hoverColor: Colors.white,
            padding: EdgeInsets.zero,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.green,
            activeTrackColor: Colors.red,
            thumbIcon: MaterialStateProperty.all(const Icon(Icons.lock,color: Colors.black)),
            value: preso,
            onChanged: (s) =>Provider.of<JanelaCtrl>(context, listen: false).telaPresaReverse()
          ),
        );
      },
    );
  }
}