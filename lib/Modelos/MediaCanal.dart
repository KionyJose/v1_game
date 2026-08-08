// ignore_for_file: file_names

class MediaCanal{
  late String nome;
  late String url;
  late String imgLocal;
  
  MediaCanal({this.imgLocal="",this.nome ="",this.url=""});

  factory MediaCanal.fromMap(Map<String, dynamic> map) {
    return MediaCanal(
      nome: map['nome']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      imgLocal: map['imgLocal']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'url': url,
        'imgLocal': imgLocal,
      };
}
