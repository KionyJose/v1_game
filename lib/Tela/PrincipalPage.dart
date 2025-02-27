// ignore_for_file: use_build_context_synchronously, file_names, deprecated_member_use
import 'dart:io';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:snappy_list_view/snappy_list_view.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/PrincipalCtrl.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Widgets/YouTubeTela.dart';
import 'package:v1_game/Widgets/cardGame.dart';
import 'package:v1_game/Widgets/videoSliders.dart';
import 'package:window_manager/window_manager.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key, required this.title});

  final String title;

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> with WindowListener {

  late PrincipalCtrl ctrlOff;
  bool naTela = false;
  // PaadGet jogadorRepository = GetIt.instance.get<PaadGet>();
  EdgeInsetsGeometry cardMargin = const EdgeInsets.symmetric(horizontal: 3);
  
  // void atualizarTela() => setState((){});

  @override
  void initState() {
    super.initState();
    // windowManager.addListener(this);
    // simulateGamepadInput();
  }
  


  @override
  void dispose() {
    debugPrint("SAIU PAGE PAGE");
    // ctrl.dispose();
    // windowManager.removeListener(this);
    super.dispose();
  } 



  @override
  void onWindowFocus() => naTela= true;

  @override
  void onWindowBlur() => naTela = false;
  
  

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (context) => PrincipalCtrl(context), // Cria o controlador aqui
      // dispose: (context, ctrl) => ctrl.dispose(), // Remove o controlador quando sair
      child: Consumer<PrincipalCtrl>(
        builder: (context, ctrl, child) {
          // debugPrint("object =========================");
          ctrl.ctx = context;
          ctrlOff = ctrl;
          return scaffold(ctrl);
          
          
        },
      ),
    );
  }

  escutaPadWid(PrincipalCtrl ctrl){
    return Selector<Paad, String>(
      selector: (context, paad) => paad.click, // Escuta apenas click
      builder: (context, valorAtual, child) {
        
        // Aguardando o próximo frame para chamar o showDialog   if(event == "HOME" && !home){
        if(!ctrl.home){
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ctrl.escutaPad(valorAtual);// Isso pode chamar o showDialog
          });
        }if(!ctrl.telaIniciada) return Container();
        return body(ctrl);
      },
    );
  }
  scaffold(PrincipalCtrl ctrl){
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener( // Escuta teclado Press;
            includeSemantics: false,
            focusNode: ctrl.keyboradEscutaNode,//ctrl.focoPrincipal,
            autofocus: false,
            onKeyEvent: (KeyEvent event) => ctrl.keyPress(event),
            child: escutaPadWid(ctrl)
          ),
      floatingActionButton: floatBtns(),
    );
  }
  escurecerTela(PrincipalCtrl ctrl){
    return  AnimatedOpacity( // Anima A Opacidade.
      opacity: ctrl.videoAtivo ? 1.0 : 0.0,
      duration: !ctrl.videoAtivo ?  const Duration(microseconds: 0) :  const Duration(seconds: 1),
      child: Transform.scale(
        scale: ctrl.scaleAnimation.value,
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }

  desfoqueTela(bool ativo){
    return TweenAnimationBuilder<double>(
      duration: const  Duration(seconds: 1),
      tween: Tween(begin: 0, end: ativo ? 5 : 0),
      builder: (context, blur, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(color: Colors.black.withOpacity(0)),
        );
      },
    );
  }

  body(PrincipalCtrl ctrl){
    bool filmes = ctrl.focusScope == ctrl.focusScopeCinema;
    return Stack(
      children: [
      backGroundAnimado(ctrl), // Fundo animado
      desfoqueTela(filmes),
      if (ctrl.telaIniciada)bodys(ctrl),// Ícones horizontais
      abaGuias(ctrl),
      escurecerTela(ctrl),// Escurecer tela      
      if (ctrl.videoAtivo)
      videoAtivo(ctrl),// Player de vídeo
      if (ctrl.videosYT.isNotEmpty && ctrl.telaIniciada && ctrl.videosShow && ctrl.selectedIndexAbaGuias == 0)
      VideoSliders(child: listVideos(ctrl)),// Lista de vídeos
    ],
    );
  }

  abaGuias(PrincipalCtrl ctrl){
    double tamanhoBloco = 80;
    double telaWidth = MediaQuery.of(context).size.width;
    return Positioned(
      left: -telaWidth + 16, // Ajuste este valor para mover para a esquerda
      top: -5,
      child: SizedBox(
        height: telaWidth/4,
        width: (telaWidth * 2) + tamanhoBloco * 1.5,
        child: FocusScope(
          node: ctrl.focusScopeAbaGuias,
          child: ScrollSnapList(
            background: Colors.red,
            padding: EdgeInsets.zero,
            listController: ctrl.scrolListAbaGuias, 
            itemCount: ctrl.listAbaGuias.length,
            onItemFocus: (i) { }, // Atualiza o índice do item em foco,
            itemSize: tamanhoBloco, // Tamanho horizontal
            itemBuilder: (context, i) {
              bool isFoco = ctrl.selectedIndexAbaGuias == i;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    decoration: isFoco ? BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.black87,
                    ) : const BoxDecoration(),
                    margin: const EdgeInsets.symmetric(vertical: 20,horizontal: 13) ,
                    width:  isFoco ? (tamanhoBloco - 26) * 3 : (tamanhoBloco -26 ),  // Largura do item base
                    duration: const Duration(milliseconds: 150),
                    child: Focus(
                      focusNode: ctrl.focusNodeAbaGuias[i],
                      onFocusChange: (hasFocus) => ctrl.onFocusChangeAbaGuias(hasFocus, i, tamanho: tamanhoBloco),
                      child:  btnAba(ctrl.listAbaGuias[i],isFoco),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    // return Container(
    //   color: Colors.black38,
    //   margin: EdgeInsets.only(top: 10,left: 50),
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.start,
    //     crossAxisAlignment: CrossAxisAlignment.end,
    //     children: [
    //       btnAba("Jogos",true),
    //       btnAba("Filmes",false),
    //       // btnAba("Series",false),
    //     ],
    //   ),
    // );
  }

  btnAba(String txt,bool foco){
    const sombra = Shadow(color: Colors.black,blurRadius: 4);
    List<Shadow> sombras = [sombra,sombra,sombra];
    final stilo = TextStyle(color: Colors.white,shadows: sombras,fontSize: foco ? 25 : 15);
    return MaterialButton(
      elevation: 0,
      // color: Colors.transparent,
      padding: EdgeInsets.zero,
      onPressed: (){},
      child: FittedBox(child: Text(txt,style: stilo,)),
    );
  }

  



  videoAtivo(PrincipalCtrl ctrl){
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.only(bottom: 80),
        height: MediaQuery.of(context).size.height * 0.70,
        width: MediaQuery.of(context).size.height * 0.70 * 1.809, // Aspect ratio 16:9
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: YoutubeTela(
            url: ctrl.videosYT[ctrl.selectedIndexVideo].urlVideo,
            func: (controlador) => ctrl.ctrlVideo = controlador,
          ),
        ),
      ),
    );
  }

  // listaIcones(PrincipalCtrl ctrl){
  //   double tamanho = 0.24;
  //   try{
  //   if(ctrl.focusScope == ctrl.focusScopeIcones)tamanho = 0.35;
  //   }catch(_){}
  //   return  Align(
  //     alignment: Alignment.topLeft,
  //     child: FocusScope(
  //       node: ctrl.focusScopeIcones,
  //       child: AnimatedContainer(          
  //         height: MediaQuery.of(context).size.height * tamanho,  // Altura do carrossel
  //         duration: const Duration(milliseconds: 100),
  //         width: double.infinity,
  //         child: CarouselSlider.builder(
            
  //           // snapAlignment: SnapAlignment. custom((i) =>  0.03 ),
  //           // snapOnItemAlignment: SnapAlignment. custom((i) =>  0.03 ),
  //           carouselController: ctrl.carouselIconesCtrl,
  //           itemCount: ctrl.focusNodeIcones.length,
  //           itemBuilder: (context, i, realIndex) {
  //             bool isFoco = ctrl.selectedIndexIcone == i;
  //             return FittedBox(
  //               child: Container(
  //               margin: const EdgeInsets.symmetric(vertical: 35),
  //               height: isFoco ? 1100 : 500, 
  //               width: 1000,
  //                 child: Focus(
  //                   focusNode: ctrl.focusNodeIcones[i],
  //                   onFocusChange: (hasFocus) => ctrl.onFocusChangeIcones(hasFocus, i),              
  //                   child: ctrl.listIconsInicial.isEmpty ? cardAnimadoAdd(ctrl, i) :  cardAnimado(ctrl, i),
  //                 ),
  //               ),
  //             );
  //           },            
  //           options: CarouselOptions(              
  //             height: MediaQuery.of(context).size.height, // Altura do carrossel
  //             aspectRatio: 14.5,
  //             initialPage: 0, // Inicia no primeiro item
  //             enableInfiniteScroll: false,
  //             viewportFraction: 0.17, // Tamanho do item visível
  //             enlargeCenterPage: false, // Desativa o aumento do item central
  //             disableCenter: true, // Desativa o alinhamento central
  //             padEnds: false, // Remove o espaçamento nas extremidades
  //             scrollDirection: Axis.horizontal,
  //             // Outras opções conforme necessário
  //             ),
  //         ),
            
  //       ),
  //     ),
  //   );
  // }
 Widget bodyIconesCinema(PrincipalCtrl ctrl, double tamanhoBloco) {
  return FocusScope(
    node: ctrl.focusScopeCinema,
    child: Container(
      margin: const EdgeInsets.only(top: 60,left: 40,bottom: 20,right: 40),
      width: MediaQuery.of(context).size.width + tamanhoBloco * 3,
      alignment: Alignment.center,
      child: GridView.builder(
        padding: const EdgeInsets.all(9),
        controller: ctrl.scrolListStream,
        itemCount: ctrl.listCinema.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 1.5, // Largura 2x maior que a altura
        ),
        itemBuilder: (context, index) => btnFilmes(ctrl,index),
      ),
    ),
  );
}
btnFilmes(PrincipalCtrl ctrl, int i){
  bool focu = i == ctrl.selectedIndexCinema;
    return Focus(
      focusNode: ctrl.focusNodeCinema[i],
      onFocusChange: (hasFocus) => ctrl.onFocusChangeCinema(hasFocus, i),
      child: FittedBox(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              image: FileImage(File(ctrl.urlImgFilme(i))),
            ),
            border: focu ? Border.all(
              color: Colors.white, // Cor da borda
              width: 3,                // Espessura da borda
            ) : null,
          ),
          alignment: Alignment.bottomCenter,
          // margin: const EdgeInsets.all(40),
          height: 200,        
          width: 300,
          child:  focu ? const Icon(Icons.play_arrow_rounded,color: Colors.white,) : Container(),
        ),
      ),
    );
  }
  bodys(PrincipalCtrl ctrl) {
    double tamanhoBloco = 120;
    return bodyPageView(ctrl,tamanhoBloco);
  }

  bodyPageView(PrincipalCtrl ctrl,double tamanhoBloco){
    return PageView(
      scrollDirection: Axis.horizontal,
      controller: ctrl.bodyCtrl,
      children: [
        bodyIconesJogos(ctrl, tamanhoBloco),
        if(ctrl.selectedIndexAbaGuias == 1) bodyIconesCinema(ctrl, tamanhoBloco),        
      ],      
    ); 
  }

  bodyIconJg(PrincipalCtrl ctrl, double tamanhoBloco){
    return FocusScope(
      node: ctrl.focusScopeIcones,
      child: ScrollSnapList(
        // margin: EdgeInsets.only(right: 600),
        listController: ctrl.scrolListIcones, 
        // allowAnotherDirection: true,
        // dynamicItemSize
        // updateOnScroll: true,
        listViewPadding: const EdgeInsets.only(left: 100 ),
        itemCount: ctrl.focusNodeIcones.length,
        onItemFocus: (i) { }, // Atualiza o índice do item em foco,
        itemSize: tamanhoBloco, // Tamanho horizontal
        itemBuilder: (context, i) {
          bool isFoco = ctrl.selectedIndexIcone == i;
          return Container(
            // margin: const EdgeInsets.only(top: 25),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                AnimatedContainer(
                  padding: const EdgeInsets.symmetric(vertical: 20) ,
                  width:  isFoco ? (tamanhoBloco -26) * 3 : (tamanhoBloco -26),  // Largura do item base
                  duration: const Duration(milliseconds: 150),
                  child: FittedBox(
                    child: Focus(
                      focusNode: ctrl.focusNodeIcones[i],
                      onFocusChange: (hasFocus) => ctrl.onFocusChangeIcones(hasFocus, i, tamanho: tamanhoBloco),
                      child: ctrl.listIconsInicial.isEmpty ? cardAnimadoAdd(ctrl, i) : cardAnimado(ctrl, i, tamanho: tamanhoBloco),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bodyIconesJogos(PrincipalCtrl ctrl, double tamanhoBloco){
    double telaWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        Positioned(
          left: -telaWidth,
          top: 50,
          child: SizedBox(
            height: telaWidth/4,
            width: (telaWidth * 2) + tamanhoBloco * 1.5,            
            child:  FocusScope(
              node: ctrl.focusScopeIcones,
              child: ScrollSnapList(
                initialIndex: 0,            
                padding: EdgeInsets.zero,
                listController: ctrl.scrolListIcones, 
                itemCount: ctrl.focusNodeIcones.length,
                onItemFocus: (i) { }, // Atualiza o índice do item em foco,
                itemSize: tamanhoBloco, // Tamanho horizontal
                itemBuilder: (context, i) {
                  bool isFoco = ctrl.selectedIndexIcone == i;
                  return Container(
                    // margin: const EdgeInsets.only(top: 25),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          padding: const EdgeInsets.symmetric(vertical: 20) ,
                          width:  isFoco ? (tamanhoBloco -26) * 3 : (tamanhoBloco -26),  // Largura do item base
                          duration: const Duration(milliseconds: 150),
                          child: FittedBox(
                            child: Focus(
                              focusNode: ctrl.focusNodeIcones[i],
                              onFocusChange: (hasFocus) => ctrl.onFocusChangeIcones(hasFocus, i, tamanho: tamanhoBloco),
                              child: ctrl.listIconsInicial.isEmpty ? cardAnimadoAdd(ctrl, i) : cardAnimado(ctrl, i, tamanho: tamanhoBloco),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
            ),
          ),
        ),
      ],
    );
  }





  listIconesOld(PrincipalCtrl ctrl){
    return Align(
      alignment: Alignment.topLeft,
      child: FocusScope(
        node: ctrl.focusScopeIcones,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          child: SnappyListView(
            // snapAlignment: SnapAlignment. custom((i) =>  0.03 ),
            // snapOnItemAlignment: SnapAlignment. custom((i) =>  0.03 ),
            controller: ctrl.slideIconesCtrl,
            scrollDirection: Axis.horizontal,
            itemCount: ctrl.focusNodeIcones.length,
            
            itemBuilder: (context, i) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Focus(
                      focusNode: ctrl.focusNodeIcones[i],
                      onFocusChange: (hasFocus) => ctrl.onFocusChangeIcones(hasFocus, i),              
                      child: ctrl.listIconsInicial.isEmpty ? cardAnimadoAdd(ctrl, i) :  cardAnimado(ctrl, i),
                    ),
                ),
              );
            }
          ),
            
        ),
      ),
    );
    
  }

  botaoTag(String str){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white54,
        borderRadius: BorderRadius.circular(5)
      ),
      child: MaterialButton(
        onPressed: (){

        },
        child: Text(str,style: const TextStyle(color: Colors.brown),),
      ),
    );
  }

  

  listVideos(PrincipalCtrl ctrl){
    double tamanho = 0.2;
    try{
    if(ctrl.focusScope == ctrl.focusScopeVideos && !ctrl.videoAtivo)tamanho = 0.27;
    }catch(_){}
    
    return  Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if(ctrl.focusScopeVideos.hasFocus)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for(int i = 0; i < ctrl.tagVideo.length; i++)
                 Focus(
                 focusNode: ctrl.focusNodeTagVid[i],
                 onFocusChange: (hasFocus) => ctrl.onFocusChangeTagVid(hasFocus, i),
                 child: botaoTag(ctrl.tagVideo[i])),
              ],
            ),
            const SizedBox(height: 20),
            FocusScope(
              node: ctrl.focusScopeVideos,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: MediaQuery.of(context).size.height * tamanho,
                width: double.infinity,
                child: CarouselSlider(
                  carouselController: ctrl.carouselVideosCtrl,
                    options: CarouselOptions(
                      pageSnapping: true,                    
                      height: MediaQuery.of(context).size.height * tamanho, // Altura do carrossel
                      autoPlay: ctrl.focusScopeVideos.hasFocus ? false : true, // Habilita autoplay quando nao focado.
                      enlargeCenterPage: true, // Centraliza e destaca o item ativo
                      enableInfiniteScroll: true,
                      viewportFraction: tamanho, // Tamanho do item visível
                      initialPage: ctrl.selectedIndexVideo,
                      // scrollDirection: Axis.vertical
                      enlargeStrategy: CenterPageEnlargeStrategy.zoom
                    ),
                    items: [
                      for(int i = 0; i < ctrl.videosYT.length; i++)
                      Focus(
                        focusNode: ctrl.focusNodeVideos[i],
                        onFocusChange: (hasFocus) => ctrl.onFocusChangeVideos(hasFocus, i),              
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          width: MediaQuery.of(context).size.width,
                          // margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Colors.white12,
                            image: DecorationImage(
                              opacity: 0.9,
                              image: NetworkImage(ctrl.videosYT[i].capaG),
                              fit: BoxFit.cover,
                            ),
                            border: ctrl.selectedIndexVideo == i && ctrl.focusScopeVideos.hasFocus ? Border.all(
                              color: Colors.blueAccent, // Cor da borda
                              width: 3,                // Espessura da borda
                            ) : null,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 60.0,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                        
                      
                    ]
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  cardAnimado(PrincipalCtrl ctrl,int index,{double tamanho = 0}){
    return MouseRegion(
      onEnter: (event) {
        ctrl.mouseDentro(index,tamanho);
      },
      onExit: (value) {
        ctrl.mouseFora(index,tamanho);
      },
      child: CardGame(
        iconInitial: ctrl.listIconsInicial[index],
        focus: ctrl.selectedIndexIcone == index,
      ),
    );
  }
  cardAnimadoAdd(PrincipalCtrl ctrl, int index){
    return AnimatedContainer(
      constraints: const BoxConstraints(
        minHeight: 175,
        minWidth: 175,
      ),
      duration: const Duration(milliseconds: 200),
      // margin: cardMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withOpacity(1.0),
            Colors.blue.withOpacity(1.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink,
            offset: const Offset(-2, 0),
            blurRadius: ctrl.selectedIndexIcone == index ? 30 : 10,
          ),
          BoxShadow(
            color: Colors.blue,
            offset: const Offset(2, 0),
            blurRadius: ctrl.selectedIndexIcone == index ? 30 : 10,
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (event) {
          // onHover(index, true);
        },
        onExit: (value) {
          // onHover(index, false);
        },
        child: AnimatedContainer(
          width: MediaQuery.of(context).size.width * 0.12 ,
          height: MediaQuery.of(context).size.width * 0.12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF000515),
          ),
          duration: const Duration(milliseconds: 100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration:  BoxDecoration(
                image: DecorationImage( fit: BoxFit.cover, image:FileImage(File("${assetsPath}BGICOdefault.png")), //AssetImage('assets/BGICOdefault.png'),
              ),),
              height: 200,
              width: 135,
              child: const FittedBox(child: Icon(Icons.add,color: Colors.white,))
              )
          ),
        ),
      ),
    );
  }

  floatBtns(){
    return  Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("Desenvolvido por: @KionyJose",style: TextStyle(color: Colors.yellowAccent.withOpacity(0.2)),)
      ],
    );
  }
  

  backGroundAnimado(PrincipalCtrl ctrl){
    return AnimatedBuilder( // crece Container e diminui.
      animation: ctrl.ctrlAnimeBgFundo,
      builder: (context, child) {
        // debugPrint(ctrl.showNewImage.toString());
        return AnimatedOpacity( // Anima A Opacidade.
          opacity: ctrl.showNewImage ? 1.0 : 0.0,
          duration: !ctrl.showNewImage ?  const Duration(milliseconds: 350) :  const Duration(seconds: 1),
          child: Transform.scale(
            scale: ctrl.scaleAnimation.value,
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(50),
              ),
              child: imagemFundo(ctrl),
            ),
          ),
        );
      },
    );
  }
  
  imagemFundo(PrincipalCtrl ctrl) {
    final item = BoxDecoration( image: DecorationImage( fit: BoxFit.cover, image: FileImage(File("${assetsPath}BGdefault.jpeg"),scale: 5)));
    if(ctrl.listIconsInicial.isEmpty){
      
      return Image.asset("${assetsPath}BGdefault.jpeg",
      fit: BoxFit.cover,
      );      
    }
    return Container(
      decoration: ctrl.imgFundoStr.isNotEmpty ? File(ctrl.imgFundoStr).existsSync() ? BoxDecoration( image: DecorationImage(fit: BoxFit.cover, image 
      : FileImage( File(ctrl.imgFundoStr),)))
      : item : item,
      // : const BoxDecoration(color: Colors.transparent),
      height: 200,
      width: 135,
      // child: focus ? Center(child: Text(iconInitial.nome,style: const TextStyle(fontSize: 25,color: Colors.white),)) : Container()
    );
  }

  
}


