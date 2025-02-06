// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';

class Notificacao with ChangeNotifier{

  bool ativo = false;
  String mensage = "";
  late IconData ico = Icons.notifications;
  Notificacao();

  notificarIn(IconData ic, String str,){
    ico = ic;
    ativo = true;
    mensage = str;
    notifyListeners();
    Timer(const Duration(seconds: 6), () => desativa());
  }

  desativa(){
    ativo = false;
    notifyListeners();
  }

  // notficaOff(BuildContext ctx, IconData ic, String str ){    
  //   Provider.of<Notificacao>(ctx, listen: false).notificarIn(ic, str);
  // }

}