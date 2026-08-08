// ignore_for_file: file_names, unused_element

import 'dart:convert';
import 'dart:io';

import 'package:v1_game/Modelos/MediaCanal.dart';

import '../Global.dart';

class MediaCatalogo{

  static List<String> listaCatalogoNomesC = ["Netflix","Prime Video","MAX","Apple TV","Disney +", "Globo Play","TeleCine","CrunchyRoll","Paramount+"];
  static List<String> listaCatalogoNomesM = ["spotify","Youtube Music","Apple Music","Deezer"];
  static const String _dbPath = "C:\\Users\\Public\\Documents\\v1_media_cards.json";

  static Future<List<MediaCanal>> catalogoCine() async =>
      _catalogoComDadosSalvos('cinema', _meuCatalogoC());

  static Future<List<MediaCanal>> catalogoMusc() async =>
      _catalogoComDadosSalvos('musica', _meuCatalogoM());

  static Future<void> salvarCatalogo(String tipo, List<MediaCanal> lista) async {
    final dados = await _lerDadosSalvos();
    dados[tipo] = lista.map((item) => item.toMap()).toList();
    await File(_dbPath).writeAsString(const JsonEncoder.withIndent('  ').convert(dados));
  }

  static Future<List<MediaCanal>> _catalogoComDadosSalvos(
      String tipo, List<MediaCanal> padrao) async {
    final dados = await _lerDadosSalvos();
    final salvos = dados[tipo];
    if (salvos is! List || salvos.isEmpty) {
      await salvarCatalogo(tipo, padrao);
      return padrao;
    }
    return salvos
        .whereType<Map>()
        .map((item) => MediaCanal.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.nome.isNotEmpty && item.url.isNotEmpty)
        .toList();
  }

  static Future<Map<String, dynamic>> _lerDadosSalvos() async {
    final file = File(_dbPath);
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  static _meuCatalogoM(){
    List<MediaCanal> list = [];
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\spotify.png",
      nome: "spotify",
      url: "https://www.spotify.com/br/"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\YoutubeMusic.png",
      nome: "Youtube Music",
      url: "https://music.youtube.com/"
    ));list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\AppleMusic.png",
      nome: "Apple Music",
      url: "https://www.AppleMusic.com/pt-br"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Deezer.png",
      nome: "Deezer",
      url: "https://www.Deezer.com/br/"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\AmazonMusic.png",
      nome: "Amazon Music",
      url: "https://music.amazon.com.br/"
    ));

    return list;
  }

  static _meuCatalogoC(){  
    List<MediaCanal> list = [];
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Netflix.png",
      nome: "Netflix",
      url: "https://www.netflix.com/br/"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\PrimeVideo.png",
      nome: "Prime Video",
      url: "https://www.primevideo.com/"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Max.png",
      nome: "MAX",
      url: "https://www.max.com/br"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\AppleTv.png",
      nome: "Apple TV",
      url: "https://tv.apple.com/br/"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Disney+.png",
      nome: "Disney +",
      url: "https://www.disneyplus.com/pt-br"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\GloboPlay.png",
      nome: "Globo Play",
      url: "https://globoplay.globo.com/"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Youtube.png",
      nome: "Youtube",
      url: "https://www.Youtube.com.br/"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\TeleCine.png",
      nome: "TeleCine",
      url: "https://www.telecine.com.br/"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\CrunchyRoll.png",
      nome: "CrunchyRoll",
      url: "https://www.crunchyroll.com/pt-br"
    ));
    list.add(MediaCanal(
      imgLocal: "${assetsPath}StreamingCapa\\Paramount+.png",
      nome: "Paramount+",
      url: "https://www.paramountplus.com/br/"
    ));

    return list;
  }

}
