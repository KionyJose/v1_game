// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:v1_game/Controllers/SonsSistema.dart';

class MovimentoSistema {

  static String vertical = "Vertical";
  static String horizontal = "Horizontal";
  static const int _zonaMortaAnalogico = 10000;
  static const Duration _intervaloAnalogico = Duration(milliseconds: 220);
  static DateTime? _ultimoAnalogicoHorizontal;
  static DateTime? _ultimoAnalogicoVertical;

   static direcaoListView(FocusScopeNode focusScope, String event){
    String estilo = "";
    
    event = _normalizaAnalogico(event);
    if(event.isEmpty) return estilo;
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
      if(estilo.isNotEmpty) SonsSistema.directionAtual();
    return estilo;
  }

  static String _normalizaAnalogico(String event) {
    if(!event.contains("ANALOGICO")) return event;
    final partes = event.split(",");
    if(partes.length < 3) return "";
    final eixo = partes[1].trim();
    final valor = num.tryParse(partes[2].trim())?.toDouble() ?? 0;
    if(valor.abs() < _zonaMortaAnalogico) return "";

    final agora = DateTime.now();
    if(eixo == "X") {
      if(_ultimoAnalogicoHorizontal != null &&
          agora.difference(_ultimoAnalogicoHorizontal!) < _intervaloAnalogico) {
        return "";
      }
      _ultimoAnalogicoHorizontal = agora;
      return valor > 0 ? "DIREITA" : "ESQUERDA";
    }
    if(eixo == "Y") {
      if(_ultimoAnalogicoVertical != null &&
          agora.difference(_ultimoAnalogicoVertical!) < _intervaloAnalogico) {
        return "";
      }
      _ultimoAnalogicoVertical = agora;
      return valor > 0 ? "CIMA" : "BAIXO";
    }
    return "";
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
