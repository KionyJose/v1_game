// ignore_for_file: file_names

import 'package:flutter/material.dart';

class Movimentosistema {

   static direcaoListView(FocusScopeNode focusScope, String event){
    if(event == "ESQUERDA" || event == "A"){//ESQUERDA
        focusScope.focusInDirection(TraversalDirection.left);
      }
      if(event == "DIREITA" || event == "D"){//DIREITA
        focusScope.focusInDirection(TraversalDirection.right);
      }
      if(event == "CIMA" || event == "W"){//CIMA
        focusScope.focusInDirection(TraversalDirection.up);
      }
      if(event == "BAIXO" || event == "S"){//BAIXO
        focusScope.focusInDirection(TraversalDirection.down);
      }
  }
}