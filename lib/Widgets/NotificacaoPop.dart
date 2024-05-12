// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:v1_game/Global.dart';

class NotificacaoPop extends StatelessWidget {
  const NotificacaoPop({super.key});

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 3), () {notificacaoPop = false;});
    return  AnimatedContainer(
      duration: const Duration(seconds: 1),
      child: Container(
          width: 350,
          height: 150,
          // color: Colors.blue,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30),bottomRight: Radius.circular(30) ),
            boxShadow:  [
              BoxShadow(
                color: Colors.white54,
                blurRadius: 2,
                spreadRadius: 1,
                offset: Offset(3, 3)
              )
            ],
            // border: BoxBorder.lerp(null, null, 2),
            gradient:  LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 31, 0, 8),
                Color.fromARGB(255, 0, 19, 36),
              ]),
          ),
          padding: const EdgeInsets.all(16),
          child:  Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.notifications, color: Colors.white),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 10),
                  RichText(
                    text:  TextSpan(
                      text: msgNotificacao, //
                      style: const TextStyle(
                          fontSize: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        
      ),
    );
  }
}