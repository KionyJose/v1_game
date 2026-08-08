// ignore_for_file: avoid_print, unused_local_variable, file_names, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Class/WebScrap.dart';
import 'package:v1_game/Widgets/LoadWid.dart';

import '../../Bando de Dados/db.dart';
import '../../Controllers/MovimentoSistema.dart';
import '../../Modelos/IconeInicial.dart';
import '../../Modelos/MediaCanal.dart';
import '../../Tela/NavegadorPasta.dart';
import '../../Tela/SeletorImagens/SeletorImagens.dart';

class Pops {
  static popTela(BuildContext ctx, Widget tela) {
    return showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: tela,
        ),
      ),
    );        
  }
  popScren( Widget tela) {
    return AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: const EdgeInsets.all(0),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: tela
        )
    );        
  }

  carregandoGames(BuildContext ctx,String str) {
    return showModalBottomSheet(
      context: ctx,
      isScrollControlled: true, // Permite expandir o conteúdo
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(ctx),
        duration: const Duration(seconds: 1), // Tempo reduzido para 200ms
      ),
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CarregandoGamesSheet(texto: str);
      },
    );
  }

  static Future<MediaCanal?> popNovoMediaCard(
      BuildContext ctx, String tipo) async {
    return showDialog<MediaCanal>(
      context: ctx,
      builder: (_) => _NovoMediaCardPop(tipo: tipo),
    );
  }


  // List<String> commandos = [];
  
  // popMenuTelHome2ss(BuildContext context) async {
  //   try{
  //   bool statePop = true;
  //   String retorno = "";
  //   int total = 7;
  //   FocusScopeNode focusScope = FocusScopeNode();
  //   String str0 = "Abrir";
  //   String str1 = "Caminho do game";
  //   String str2 = "Caminho de Imagem";
  //   String str3 = "Imagem da Download";
  //   String str4 = "Atalhos";
  //   String str5 = "Excluir Card";
  //   String str6 = "Add";

  //   List<FocusNode> focusNodes = List.generate(total, (value)=> FocusNode());


  //   comandos(BuildContext context, String event){
  //     int total = 0;
  //     if(commandos.length == 2){
  //       commandos.removeAt(0);
  //       commandos.add(event);
  //       if(commandos[0] == "SELECT")total++;
  //       if(commandos[1] == "SELECT")total++;
  //       if(total == 2) Navigator.pop(context, "");
  //       if(total == 2) return false;
  //     }
  //     commandos.add(event);
  //     return true;
  //   }

  //   escutaPad(String event) {
  //     if(!statePop || event =="") return;
  //     debugPrint("=======   Escuta Pop Menu  =======");

  //     statePop = comandos(context, event);
      

  //     MovimentoSistema.direcaoListView(focusScope, event);

  //     if(event == "3"){//START
  //       statePop = false;
  //       Navigator.pop(context, "");
  //     }
  //     if(event == "2"){//Entrar
  //     debugPrint("======================================== $event SAINDOO");
  //       statePop = false;
  //       if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
  //       if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
  //       if (focusNodes[2].hasFocus) Navigator.pop(context, str2);
  //       if (focusNodes[3].hasFocus) Navigator.pop(context, str3);
  //       if (focusNodes[4].hasFocus) Navigator.pop(context, str4);
  //       if (focusNodes[5].hasFocus) Navigator.pop(context, str5);
  //       if (focusNodes[6].hasFocus) Navigator.pop(context, str6);
  //       statePop = true;
  //     }
  //   }
    





  //   btn(String str, FocusNode focus, bool iconActive, ico) {
  //     return Padding(
  //       padding: const EdgeInsets.all(8.0),
  //       child: ClipRRect(
  //         borderRadius: BorderRadius.circular(30),
  //         child: Container(
  //           color: Colors.black38,
  //           height: 40,
  //           child: MaterialButton(
  //               focusNode: focus,
  //               autofocus: str == str0 ? true : focus.hasFocus,
  //               focusColor: Colors.white70,
  //               child: Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   if (iconActive) ico,
  //                   Text(str,
  //                       style: const TextStyle(
  //                         fontSize: 18,
  //                         color: Colors.white,
  //                       )),
  //                 ],
  //               ),
  //               onPressed: () => Navigator.pop(context, str)),
  //         ),
  //       ),
  //     );
  //   }
    
  //   await showDialog(
  //       context: context,
  //       builder: (_) {
  //         return Selector<Paad, String>(
  //           selector: (_, paad) => paad.click, // Escuta apenas click     
  //           builder: (_, valorAtual, child) {
  //             // WidgetsBinding.instance.addPostFrameCallback((_) {
  //               escutaPad(valorAtual);  // Isso pode chamar o showDialog
  //             // });
  //             return KeyboardListener(
  //               focusNode: FocusNode(),
  //               onKeyEvent: (KeyEvent event) {
  //                 if (event is KeyDownEvent) {
  //                   // Verifica a tecla pressionada
  //                   MovimentoSistema.direcaoListView(focusScope, event.logicalKey.keyLabel);
  //                   if (event.logicalKey == LogicalKeyboardKey.digit3) {
  //                     Navigator.pop(context, "");
  //                   } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
  //                     if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
  //                     if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
  //                     if (focusNodes[2].hasFocus) Navigator.pop(context, str2);
  //                     if (focusNodes[3].hasFocus) Navigator.pop(context, str3);
  //                     if (focusNodes[4].hasFocus) Navigator.pop(context, str4);                      
  //                     if (focusNodes[5].hasFocus) Navigator.pop(context, str5);                    
  //                     if (focusNodes[6].hasFocus) Navigator.pop(context, str6);
  //                   }
  //                   debugPrint(event.logicalKey.toString());
  //                 }
  //               },
  //               child: AlertDialog(
                  
  //                 backgroundColor: Colors.transparent,
  //                 contentPadding:
  //                     const EdgeInsets.only(left: 8, right: 8, bottom: 4),
  //                 content: ClipRRect(
  //                   borderRadius: BorderRadius.circular(20),
  //                   child: Container(
  //                     color: Colors.white.withOpacity(0.9),
  //                     child: Container(
  //                         // container da Tela ====================================
  //                         color: Colors.black38,
  //                         height: MediaQuery.of(context).size.height * 0.55,
  //                         width: MediaQuery.of(context).size.width * 0.17,
  //                         child: FocusScope(
  //                           // autofocus: true,
  //                           node: focusScope,
  //                           child: ListView(children: [
  //                             const SizedBox(height: 5),
  //                             const Center(
  //                                 child: Text(
  //                               "Mais Opções",
  //                               style: TextStyle(
  //                                   color: Colors.white,
  //                                   fontSize: 22,
  //                                   fontWeight: FontWeight.bold),
  //                             )),
  //                             const SizedBox(height: 20),
  //                             btn(str0, focusNodes[0], false, null),
  //                             btn(str1, focusNodes[1], false, null),
  //                             btn(str2, focusNodes[2], false, null),
  //                             btn(str3, focusNodes[3], false, null),
  //                             btn(str4, focusNodes[4], false, null),
  //                             btn(str5, focusNodes[5], false, null),
  //                             // const Spacer(),
              
  //                             Row(
  //                               mainAxisAlignment: MainAxisAlignment.end,
  //                               children: [
  //                                 btn(
  //                                   str6,
  //                                   focusNodes[6],
  //                                   true,
  //                                   const Icon(
  //                                     Icons.add,
  //                                     color: Colors.white,
  //                                   ),
  //                                 ),
  //                               ],
  //                             ),
  //                           ]),
  //                         )),
  //                   ),
  //                 ),
  //               ),
  //             );
  //           }
  //         );
  //       }).then((value) => retorno = value.toString());

  //   return retorno;
  //   }catch(e){
  //     debugPrint(e.toString());
  //     // Pops().msgSimples(ctx,"ERRO = 1$e");
  //   }
  // }

 

  msgSimples(BuildContext context, String str) async{
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: const EdgeInsets.all(0),
              content: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                    height: 200,
                    // decoration: decorationBOX,
                    color: Colors.green[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 125,
                          width: double.maxFinite,
                          child: ListView(
                            children: [
                              const SizedBox(height: 15),
                              Text(str,style: const TextStyle(fontSize: 18, color: Colors.white),softWrap: true, textAlign: TextAlign.center,),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 70,
                          width: 250,
                          child: MaterialButton(
                            onPressed: ()  =>  Navigator.pop(context,"OK"),
                            child: const Text('OK',
                                style: TextStyle(
                                    fontSize: 25, color: Colors.white)),
                          ),
                        )
                      ],
                    )),
              ),
            ));
  }


  





  
  msgSN(BuildContext context, String str) async { 
    try{
      String retorno = "";  
      bool statePop = true; 
      List<FocusNode> focusNodes = [
        FocusNode(),
        FocusNode(),
      ];

      FocusScopeNode focusScope = FocusScopeNode();
      String str1 = "Sim";
      String str0 = "Nao";
      //teste1
      btn(String str, FocusNode focus) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              color: Colors.white70,
              height: 60,
              child: MaterialButton(
                  focusNode: focus,
                  autofocus: str == str0 ? true : focus.hasFocus,
                  focusColor: Colors.black45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [ 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(str,
                        style:  const TextStyle(
                          fontSize: 25,
                          color: Colors.black ,
                        )),
                      ),
                    ],
                  ),
                  onPressed: () {                  
                      if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
                      if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
                  } ),
            ),
          ),
        );
      }

    
      escutaPad(String event) {
        if(!statePop || event =="") return;
        debugPrint("=======   Escuta Pop S/N   =======");
        debugPrint("Click ==>>  $event");
        MovimentoSistema.direcaoListView(focusScope, event);
        if(event == "3"){//START
          statePop = false;
          Navigator.pop(context, "");
        }
        if(event == "2"){//Entrar
          statePop = false;
          if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
          if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
        }
      }

      await showDialog(
        context: context,
        builder: (_) => Selector<Paad, String>(
          selector: (_, paad) => paad.click, // Escuta apenas click      
          builder: (_, valorAtual, child) {
            escutaPad(valorAtual);         
            return KeyboardListener(
              //KeyboardListener
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent) {
                  // Verifica a tecla pressionada
                  if (event.logicalKey == LogicalKeyboardKey.keyA) {
                    focusScope.focusInDirection(TraversalDirection.left);
                    debugPrint(event.logicalKey.toString());
                  } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
                    focusScope.focusInDirection(TraversalDirection.right);
                    debugPrint(event.logicalKey.toString());
                  } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
                    statePop = false;
                    Navigator.pop(context, "");
                  } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
                    statePop = false;
                    if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
                    if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
                  }
                }
              },
              child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: const EdgeInsets.all(0),
              content: ClipRRect(
                borderRadius: BorderRadius.circular(20),  
                child: Container(
                height: 250,
                width: 380,
                // decoration: decorationBOX,
                color: Colors.grey[300],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 15),
                    Flexible(
                      flex: 1,
                      child: Text(
                        str,
                        style: const TextStyle(fontSize: 25, color: Colors.black),
                        softWrap: true,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FocusScope(
                      // autofocus: true,
                      node: focusScope,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            btn(str0,focusNodes[0]),
                            btn(str1, focusNodes[1])
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
              ),
            ));
          }
        ),
      ).then((value) => retorno = value.toString());
      return retorno;
    }catch(e){
      debugPrint(e.toString());
      debugPrint(e.toString());
    }
  }

  navPasta(BuildContext context,  String caminho, String tarefa, List<IconInicial> listiconIni, int index) async {    
    DB db = DB();
    try{
    var value = await showDialog(
      context: context, 
      builder: (context) => Pops().popScren(const NavPasta()),
    );
    if (value == null) return;
    if (value[0] == "caminho") {
      if(tarefa == "Caminho do game"){
        listiconIni[index].local = value[1];
        await db.attDados(listiconIni);
      }
      if(tarefa == "Imagem de capa" || tarefa == 'Caminho de Imagem'){
        listiconIni[index].imgStr = value[1];
        await db.attDados(listiconIni);
      }
      if(tarefa == "Add"){
        List<String> campos = [];

        String nome = value[1] as String;
        nome = nome.split('\\').last;
        nome = nome.split('.').first;
        
        if(value[2] != "") nome = value[2];

        campos.add("item-${listiconIni.length}");        
        campos.add("lugar: ${listiconIni.length}");        
        campos.add("nome: $nome");        
        campos.add("local: ${value[1]}");        
        campos.add("img: ");        
        campos.add("imgAux: caminho/.png");
        IconInicial ico = IconInicial(campos);
        // ico.local = value[1];

        listiconIni.insert(0,ico);
        await db.attDados(listiconIni);
        return nome;
      }
    }
    if (value[0] == "alterado") {
      // saveObgrigatorio = true;
    } else {
      // saveObgrigatorio = false;
    }
    debugPrint("Finalizei navPasta dentro");
    }catch(e){
      debugPrint("Erro nav dentro = $e");
    }
  }
}

class _CarregandoGamesSheet extends StatefulWidget {
  final String texto;

  const _CarregandoGamesSheet({required this.texto});

  @override
  State<_CarregandoGamesSheet> createState() => _CarregandoGamesSheetState();
}

class _CarregandoGamesSheetState extends State<_CarregandoGamesSheet> {
  final FocusNode _focusNode = FocusNode();
  late final DateTime _abriuEm;
  bool _fechando = false;

  @override
  void initState() {
    super.initState();
    _abriuEm = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _podeFechar =>
      DateTime.now().difference(_abriuEm) >= const Duration(seconds: 2);

  void _tentarFechar(BuildContext context, String event) {
    if (_fechando || (event != '2' && event != '3')) return;
    if (!_podeFechar) return;
    _fechando = true;
    Navigator.pop(context);
    try {
      Provider.of<Paad>(context, listen: false).click = '';
      Provider.of<Paad>(context, listen: false).attTela();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Selector<Paad, String>(
      selector: (_, paad) => paad.click,
      builder: (context, click, child) {
        if (click.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _tentarFechar(context, click);
          });
        }

        return KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (event) {
            if (event is! KeyDownEvent) return;
            final comando =
                MovimentoSistema.convertKeyBoard(event.logicalKey.keyLabel);
            _tentarFechar(context, comando);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 50),
            margin: const EdgeInsets.only(bottom: 65),
            width: 2000,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: Colors.black87,
              boxShadow: [
                BoxShadow(
                  blurRadius: 30,
                  color: Colors.deepPurple.withOpacity(0.2),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  blurRadius: 30,
                  color: Colors.blue.withOpacity(0.2),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const LoadingIco(),
                const SizedBox(height: 15),
                Text(widget.texto, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NovoMediaCardPop extends StatefulWidget {
  final String tipo;

  const _NovoMediaCardPop({required this.tipo});

  @override
  State<_NovoMediaCardPop> createState() => _NovoMediaCardPopState();
}

class _NovoMediaCardPopState extends State<_NovoMediaCardPop> {
  final _nomeCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _urlCtrl.dispose();
    _imgCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarImagem() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) return;
    final result = await Pops.popTela(context, SeletorImagens(nome: nome));
    if (result is String && result.isNotEmpty) {
      final caminho = await WebScrap.downloadImage(result, nome);
      _imgCtrl.text = caminho.contains("Erro::") ? result : caminho;
      setState(() {});
    }
  }

  void _salvar() {
    final nome = _nomeCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    final img = _imgCtrl.text.trim();
    if (nome.isEmpty || url.isEmpty || img.isEmpty) return;
    Navigator.pop(
      context,
      MediaCanal(nome: nome, url: url, imgLocal: img),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xF0131722),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Novo card de ${widget.tipo}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            _campo(_nomeCtrl, 'Nome'),
            const SizedBox(height: 12),
            _campo(_urlCtrl, 'URL para abrir'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo(_imgCtrl, 'Caminho da imagem')),
                const SizedBox(width: 10),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _buscarImagem,
                    icon: const Icon(Icons.image_search),
                    label: const Text('Buscar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
