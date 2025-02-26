// ignore_for_file: file_names, unused_element

import 'package:v1_game/Modelos/CinemaCanal.dart';

class CinemaCatalogo{

  static List<String> listaCatalogoNomes = ["Netflix","Prime Video","MAX","Apple TV","Disney +", "Globo Play","TeleCine","CrunchyRoll","Paramount+"];
  
  static  catalogo () =>  _meuCatalogo();

  static _meuCatalogo(){  
    List<CinemaCanal> list = [];
    list.add(CinemaCanal(
      imgLocal: "assets/StreamingCapa/Netflix.png",
      nome: "Netflix",
      url: "https://www.netflix.com/br/"
    ));
    list.add(CinemaCanal(
      imgLocal: "assets/StreamingCapa/PrimeVideo.png",
      nome: "Prime Video",
      url: "https://www.primevideo.com/"
    ));
    list.add(CinemaCanal(
      imgLocal: "assets/StreamingCapa/Max.png",
      nome: "MAX",
      url: "https://www.max.com/br"
    ));
    list.add(CinemaCanal(
      imgLocal: "assets/StreamingCapa/AppleTv.png",
      nome: "Apple TV",
      url: "https://tv.apple.com/br/"
    ));
    list.add(CinemaCanal(
      imgLocal: "assets/StreamingCapa/Disney+.png",
      nome: "Disney +",
      url: "https://www.disneyplus.com/pt-br"
    ));
    list.add(CinemaCanal(
      imgLocal: "assets/StreamingCapa/GloboPlay.png",
      nome: "Globo Play",
      url: "https://globoplay.globo.com/"
    ));
    list.add(CinemaCanal(
      imgLocal: "assets/StreamingCapa/TeleCine.png",
      nome: "TeleCine",
      url: "https://www.telecine.com.br/"
    ));
    list.add(CinemaCanal(
      imgLocal: "assets/StreamingCapa/CrunchyRoll.png",
      nome: "CrunchyRoll",
      url: "https://www.crunchyroll.com/pt-br"
    ));
    list.add(CinemaCanal(
      imgLocal: "assets/StreamingCapa/Paramount+.png",
      nome: "Paramount+",
      url: "https://www.paramountplus.com/br/"
    ));

    return list;
  }

}