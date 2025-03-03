// ignore_for_file: file_names

class ImgWebScrap {
  String title;
  String imageUrl;
  String tipo;
  String altura;
  String largura;

  ImgWebScrap({this.altura ="", this.largura = "", this.title="",  this.imageUrl = "", this.tipo = ""});

  fromMapImgFinal(map){
    title = map['alt']?? "";
    imageUrl = map['src']?? "";
    if(imageUrl.isNotEmpty) imageUrl = "https://wallpapercave.com/$imageUrl";
    tipo = map['class']?? "";
    altura = map['height']?? "";
    largura = map['width']?? ""; 

  }
}