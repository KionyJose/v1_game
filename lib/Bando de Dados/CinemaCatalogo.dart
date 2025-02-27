// ignore_for_file: file_names, unused_element

import 'package:v1_game/Modelos/CinemaCanal.dart';

import '../Global.dart';

class CinemaCatalogo{

  static List<String> listaCatalogoNomes = ["Netflix","Prime Video","MAX","Apple TV","Disney +", "Globo Play","TeleCine","CrunchyRoll","Paramount+"];
  
  static  catalogo () =>  _meuCatalogo();

  static _meuCatalogo(){  
    List<CinemaCanal> list = [];
    list.add(CinemaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Netflix.png",
      nome: "Netflix",
      url: "https://www.netflix.com/br/"
    ));
    list.add(CinemaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\PrimeVideo.png",
      nome: "Prime Video",
      url: "https://www.primevideo.com/"
    ));
    list.add(CinemaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Max.png",
      nome: "MAX",
      url: "https://www.max.com/br"
    ));
    list.add(CinemaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\AppleTv.png",
      nome: "Apple TV",
      url: "https://tv.apple.com/br/"
    ));
    list.add(CinemaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Disney+.png",
      nome: "Disney +",
      url: "https://www.disneyplus.com/pt-br"
    ));
    list.add(CinemaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\GloboPlay.png",
      nome: "Globo Play",
      url: "https://globoplay.globo.com/"
    ));
    list.add(CinemaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\TeleCine.png",
      nome: "TeleCine",
      url: "https://www.telecine.com.br/"
    ));
    list.add(CinemaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\CrunchyRoll.png",
      nome: "CrunchyRoll",
      url: "https://www.crunchyroll.com/pt-br"
    ));
    list.add(CinemaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Paramount+.png",
      nome: "Paramount+",
      url: "https://www.paramountplus.com/br/"
    ));

    return list;
  }

}