// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:v1_game/Controllers/SonsSistema.dart';

class MovimentoSistema {

  static String vertical = "Vertical";
  static String horizontal = "Horizontal";

   static direcaoListView(FocusScopeNode focusScope, String event){
    String estilo = "";
    if(event == "ESQUERDA" || event == "A"){//ESQUERDA
        focusScope.focusInDirection(TraversalDirection.left);
        estilo = horizontal;
      }
      if(event == "DIREITA" || event == "D"){//DIREITA
        focusScope.focusInDirection(TraversalDirection.right);
        estilo = horizontal;
      }
      if(event == "CIMA" || event == "W"){//CIMA
        focusScope.focusInDirection(TraversalDirection.up);
        estilo = vertical;
      }
      if(event == "BAIXO" || event == "S"){//BAIXO
        focusScope.focusInDirection(TraversalDirection.down);
        estilo = vertical;
      }
      if(estilo.isEmpty) SonsSistema.click();
      if(estilo.isNotEmpty) SonsSistema.direction();
    return estilo;
  }

  static String convertKeyBoard(String key){
    switch(key){
      case"Enter": return "2";
      case"Backspace":return "3";
      case"Escape":return "3";
      case"A":return "ESQUERDA";
      case"D":return "DIREITA";       
      case"W":return "CIMA";
      case"S":return "BAIXO";

      case"E": return"RB";
      case"Q": return"LB";
      
      // case"Arrow Right":return "DIREITA";
      // case"Arrow Left":return "ESQUERDA";      
      // case"Arrow Up":return "CIMA";
      // case"Arrow Down":return "BAIXO";
      
      default: return "";
    }
  }
}