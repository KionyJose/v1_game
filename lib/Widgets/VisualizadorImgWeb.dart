// ignore_for_file: file_names, must_be_immutable

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Modelos/ImgWebScrap.dart';
import 'package:v1_game/Widgets/LoadWid.dart';

class VisualizadorImgWeb extends StatefulWidget {
  const VisualizadorImgWeb({ required this.list, super.key});
  final List<ImgWebScrap> list;
  static FocusScopeNode focusScope = FocusScopeNode();
  static CarouselSliderController listCtrl = CarouselSliderController();

  @override
  State<VisualizadorImgWeb> createState() => _VisualizadorImgWebState();
}

class _VisualizadorImgWebState extends State<VisualizadorImgWeb> {
  String nomeImg = "";
  int indexFoto = 0;

  escutaPad(BuildContext ctx, String event){
    // if(nomeImg.isEmpty){
    //   if
    //   nomeImg =  widget.list.first.imageUrl;
    // }
    
    if(event == "DIREITA" || event == "ESQUERDA"){
      MovimentoSistema.direcaoListView(VisualizadorImgWeb.focusScope, event);
      if(event == "DIREITA")VisualizadorImgWeb.listCtrl.nextPage();
      if(event == "ESQUERDA")VisualizadorImgWeb.listCtrl.previousPage();
    }
    if(event == "3"){
      return Navigator.pop(ctx);}
    else if (event == "2"){ 
      return Navigator.pop(ctx,nomeImg);
    }    
  }

  keyPress(BuildContext ctx, KeyEvent key) async {
    if (key is KeyDownEvent || key is KeyRepeatEvent) {      
      debugPrint("Teclado Press: ${key.logicalKey.debugName}");
      String event = MovimentoSistema.convertKeyBoard(key.logicalKey.keyLabel);
      escutaPad(ctx, event);
    }
  }

  onFocusChangeImg(BuildContext ctx, int index){
    // nomeImg = widget.list[index].imageUrl;
    // indexFoto = index;
    debugPrint(" ================${index.toString()}" );
    debugPrint(index.toString());
    
  }

  @override
  Widget build(BuildContext context) {
    return escutaTeclado(context);
  }

  escutaTeclado(BuildContext context){
    return  KeyboardListener( // Escuta teclado Press;
      includeSemantics: false,
      focusNode: FocusNode(),//ctrl.focoPrincipal,
      autofocus: false,
      onKeyEvent: (KeyEvent event) => keyPress(context,event),
      child: escutaPadWid(context)
    );
  }

  escutaPadWid(BuildContext context){
    return Selector<Paad, String>(
      selector: (context, paad) => paad.click, // Escuta apenas click
      builder: (context, valorAtual, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          escutaPad(context, valorAtual);// Isso pode chamar o showDialog
        });
        return Stack(
          children: [
            body(context), 
            const Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 120),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.arrow_back_ios,color: Colors.white),
                    Icon(Icons.arrow_forward_ios,color: Colors.white),
                  ],
                ),
              ),
            ),           
            Align(
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10,),
                    padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black45,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("B | O  -",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20)),
                        Text(" Voltar  ",style: TextStyle(color: Colors.white,fontSize: 18)),
                        Icon(Icons.backspace_rounded,color: Colors.red),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 10,bottom: 30 ),
                    padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black45,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("X | A  -",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 20)),
                        Text(" Download  ",style: TextStyle(color: Colors.white,fontSize: 18)),
                        Icon(Icons.download,color: Colors.blue),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        
      },
    );
  }

  body(BuildContext context) {
    return  Center(
      child: FocusScope(
          node: VisualizadorImgWeb.focusScope,
          child: CarouselSlider(
            carouselController: VisualizadorImgWeb.listCtrl,
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height * 1.0,
                onPageChanged: (index, ctrls)  {
                  nomeImg = widget.list[index].imageUrl;
                  indexFoto = index;
                  // debugPrint(" ================${index.toString()}" );
                  // debugPrint(index.toString());
                  
                },
                pageSnapping: true,                    
                autoPlay: false, // Habilita autoplay quando nao focado.
                enlargeCenterPage: true, // Centraliza e destaca o item ativo
                enableInfiniteScroll: true,
                viewportFraction: 0.8, // Tamanho do item visível
                initialPage: 0,
                // scrollDirection: Axis.vertical
                // enlargeStrategy: CenterPageEnlargeStrategy.zoom
              ),
              items: [
                for(int i = 0; i < widget.list.length; i++)
                GestureDetector(
                  onTap: (){                    
                    return Navigator.pop(context,widget.list[i].imageUrl);
                  },
                  child: Focus(
                    focusNode: FocusNode(),
                    onFocusChange: (hasFocus) => hasFocus ? onFocusChangeImg(context,i) : null,              
                    child: Stack(
                      children: [
                        Align(
                      alignment: Alignment.center,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            child: CachedNetworkImage(
                              imageUrl: widget.list[i].imageUrl, // Substitua pelo URL da sua imagem
                              placeholder: (context, url) => const Padding(
                                padding:  EdgeInsets.all(49),
                                child:  SizedBox(child: LoadingIco(color: Colors.amber,)),
                              ), // Indicador de progresso
                              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error,size: 200,color: Colors.black12,)), // Ícone de erro (opcional)
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.only(left: 10,top: 5,bottom: 30 ),
                            padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
                            decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Colors.black45,
                          ),
                          child: Text("${widget.list[i].largura}x${widget.list[i].altura} - ${widget.list[i].imageUrl.split('.').last.toUpperCase()}",style: const TextStyle(color: Colors.white),),
                                              ),
                        ),
      
                      ],
                    ),
                    
                     
                  ),
                ),
      
                
        
        
              ]
            ),
        
      ),
    );
  }
}