// ignore_for_file: file_names

class VideoYT{
  late String titulo;
  late String urlVideo;
  late String capaP;
  late String capaM;
  late String capaG;
  late String descricao;
  late String canal;
  late String data;
  late String videoID;
  late String nomeGame;

  VideoYT();

   // Factory para criar um objeto VideoYT a partir de um map
  fromMap(Map<String, dynamic> map, String nomeGme) {
      nomeGame = nomeGme;
      titulo = map['snippet']['title'];
      urlVideo = 'https://www.youtube.com/watch?v=${map['id']['videoId']}';
      capaP = map['snippet']['thumbnails']['default']['url'];
      capaM = map['snippet']['thumbnails']['medium']['url'];
      capaG = map['snippet']['thumbnails']['high']['url'];
      descricao = map['snippet']['description'];
      canal = map['snippet']['channelTitle'];
      data = map['snippet']['publishedAt'];
      videoID = map['id']['videoId'];
    
  }

  // Converte um objeto VideoYT para um map (opcional)
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'urlVideo': urlVideo,
      'capaP': capaP,
      'capaM': capaM,
      'capaG': capaG,
      'descricao': descricao,
      'canal': canal,
      'data': data,
      'videoID': videoID,
    };
  }


}