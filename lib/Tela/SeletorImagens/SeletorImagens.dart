// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Tela/SeletorImagens/SeletorImgCtrl.dart';
import 'package:v1_game/Widgets/LoadWid.dart';

class SeletorImagens extends StatefulWidget {
  const SeletorImagens({required this.nome, super.key});
  final String nome;

  @override
  State<SeletorImagens> createState() => _SeletorImagensState();
}

class _SeletorImagensState extends State<SeletorImagens> {
  late SeletorImgCtrl ctrl;

  @override
  void initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SeletorImgCtrl(context,widget.nome), // Cria o controlador aqui
      child: Consumer<SeletorImgCtrl>(
        builder: (context, ctrlNew, child) {
          ctrl = ctrlNew;
          return scaffold();
        }
      ),
    );
  }
  escutaPadWid(){
    return Selector<Paad, String>(
      selector: (context, paad) => paad.click, // Escuta apenas click
      builder: (context, valorAtual, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ctrl.escutaPad(valorAtual);// Isso pode chamar o showDialog
          });
        return body();
      },
    );
  }
  escutaTeclado(){
    return  KeyboardListener( // Escuta teclado Press;
      includeSemantics: false,
      focusNode: FocusNode(),//ctrl.focoPrincipal,
      autofocus: false,
      onKeyEvent: (KeyEvent event) => ctrl.keyPress(event),
      child: escutaPadWid()
    );
  }

  scaffold() {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          // padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ctrl.load ? const LoadingIco() : escutaTeclado(),
        ),
      ),
    );
  }

  body(){
    return  Center(
      child: FocusScope(
          node: ctrl.focusScope,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            txtNome(),
            if(ctrl.listUser.isNotEmpty)
            gridUsers(),
            if(ctrl.listUser.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 15),
              child: Text("Nada Encontrado.",style: TextStyle(color: Colors.white,fontSize: 25)),
            ),
        
          ],
        ),
      ),
    );
  }
  final GlobalKey _textFieldKey = GlobalKey();
  txtNome(){
    final renderBox = _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10,bottom: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              // height: MediaQuery.of(context).size.height * 0.1,
              width: MediaQuery.of(context).size.width * 0.2,
              child: TextField(
                key: _textFieldKey,
                decoration: InputDecoration(
                  border:OutlineInputBorder(
                    gapPadding: 3,
                    borderRadius: BorderRadius.circular(15),                
                  ),
                ),
                focusNode: ctrl.txtFoco,

                onChanged: (str) => ctrl.escreveTxt(str),
                onTap: () => ctrl.txtSelecionado(""),
                // onFieldSubmitted: (str)=>ctrl.txtSelecionado(str),
                // onChanged: (str)=>ctrl.txtSelecionado(str),
                onEditingComplete: () {},
                controller: ctrl.txtNome,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
                
              ),
            ),
            if(ctrl.txtFoco.hasFocus || ctrl.buscaFocos.hasFocus)...[              
              const SizedBox(width: 10),
              Focus(
                focusNode: ctrl.buscaFocos,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: ctrl.buscaFocos.hasFocus ? Colors.amber : Colors.white,
                  ),
                  margin: const EdgeInsets.only(top: 10,bottom: 3),
                  width: (MediaQuery.of(context).size.width * 0.2) / 4, 
                  height: renderBox?.size.height,
                  child: MaterialButton(onPressed: ()=> ctrl.clickBtnBuscar(),
                  child: const Icon(Icons.search,color: Colors.black,),),
                ),
              ),
            ],
             if(ctrl.teclando)...[
              const SizedBox(width: 10),
              const Row(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.lock,color: Colors.red,),
                  ),
                  Text("O / B",style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),),
                  SizedBox(width: 10),
                  Text("-  2x Para voltar a tela",style: TextStyle(color: Colors.white),)
                ],
              )
            ]
            
      ],
    );
  }

  Widget gridUsers() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: GridView.builder(
          padding: const EdgeInsets.all(9),
          controller: ctrl.scrollGridCtrl,
          itemCount: ctrl.listUser.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 9,
            mainAxisSpacing: 9,
            childAspectRatio: 1.0, // Largura 2x maior que a altura
          ),
          itemBuilder: (context, index) {
            // bool foco = index == ctrl.selectedIndexGrid;
            return btnUser(index);
          }
        ),
      ),
    );
  }

  btnUser(int index){
    const sdw = Shadow(color: Colors.black,blurRadius: 5);
    bool foco = index == ctrl.selectedIndexGrid;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(ctrl.listUser[index].imageUrl), // Usando NetworkImage para carregar a imagem diretamente da URL
          fit: BoxFit.cover, // Ajusta a imagem para cobrir todo o container, por exemplo
        ),
        border: foco ? Border.all(
          color: Colors.amber, // Cor da borda
          width: 3,                // Espessura da borda
        ) : null,
      ),
      height: MediaQuery.of(context).size.height * 0.2,
      width: MediaQuery.of(context).size.width * 0.2,
      // color: Colors.blue,
      child: Focus(
        focusNode: ctrl.focusNodesGrid[index],
        onFocusChange: (value) => value?  ctrl.selectedIndexGrid = index : null,
        child: GestureDetector(
          onTap: () => ctrl.clickPasta(ctrl.listUser[index].title),
          // padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Container(
                  //   alignment: Alignment.center,                    
                  //   child: ClipRRect(
                  //     borderRadius: BorderRadius.circular(5),
                  //     child: Image.network(ctrl.listUser[index].imageUrl),
                  //   ),
                  // ),
                  Container(
                    padding: const EdgeInsets.only(bottom: 5),
                    color: Colors.black87,
                    child: Center(
                      child: SelectableText(
                        ctrl.listUser[index].title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 5,top: 2),
                child: Icon(Icons.folder,color: Colors.white,shadows: [sdw],),
              ),
            ],
          ),
        ),
      ),
    );
  }
}