// ignore_for_file: file_names

import 'package:flutter/material.dart';

class Item{
  late String nome;
  late Icon icone;
  late bool pasta;
  late String caminho;
  late String extencao;
  late bool url;

  Item();

  addArquivo(String caminhoPasta,extencaoIN ,nomeSemExtensao, setUrl){
    caminho = caminhoPasta;
    icone = const Icon(Icons.insert_drive_file,color: Colors.white);
    pasta = false;
    nome = nomeSemExtensao;
    extencao = extencaoIN;
    url = setUrl;

  }
  addPasta(String caminhoPasta , nomePasta){
    caminho = caminhoPasta;
    icone = const Icon(Icons.folder_open,color: Colors.white);
    pasta = true;
    nome = nomePasta;
    extencao = "";
    url = false;

  }
  // addDefault(){
  //   // caminho = caminhoPasta;
  //   icone = const Icon(Icons.folder,color: Colors.white);
  //   pasta = true;
  //   // nome = nomePasta;
  //   extencao = "";
  // }



}