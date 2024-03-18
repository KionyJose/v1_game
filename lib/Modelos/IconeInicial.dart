
// ignore_for_file: file_names

class IconInicial{

  // item-01
  // lugar: 01
  // nome: Harry Pother
  // local: D:\\GAMES\\HOGWARTS LEGACY\\Hogwarts Legacy\\Phoenix\\Binaries\\Win64\\HogwartsLegacy.exe
  // img: C:\\Users\\kiony\\OneDrive\\Imagens\\Walpappers\\1102284.jpg
  // imgAux: caminho/.png


  List<String> dados = [];
  late int lugar; 
  late String nome;  
  late String local;
  late String imgStr;
  late String imgAuxStr;


  IconInicial(List<String> list){
    dados = list;
    organizaDados();

  }


  organizaDados(){    
    for(String linha in dados){
      List<String> items = linha.split(": ");
      switch(items[0]){
        case"lugar": lugar = int.parse(items[1]);
        case"nome": nome = items[1];
        case"local": local = items[1];
        case"img": imgStr = items[1];
        case"imgAux": imgAuxStr = items[1];
      }
    }

  }



}