// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:v1_game/Class/wallpapercave_image_cache.dart';
import '../../Interface/launcher_pad_scope.dart';
import 'package:v1_game/Tela/SeletorImagens/SeletorImgCtrl.dart';
import 'package:v1_game/Widgets/LoadWid.dart';

class SeletorImagens extends StatefulWidget {
  const SeletorImagens({required this.nome, this.buscar, super.key});
  final String nome;
  final Future<List<dynamic>?> Function(String)? buscar;

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
      create: (context) => SeletorImgCtrl(context, widget.nome,
          buscar: widget.buscar), // Cria o controlador aqui
      child: Consumer<SeletorImgCtrl>(builder: (context, ctrlNew, child) {
        ctrl = ctrlNew;
        return scaffold();
      }),
    );
  }

  Widget escutaTeclado() => LauncherPadScope(
        menu: false,
        enabled: ctrl.stateTela && !ctrl.teclando,
        onCommand: (event) {
          if (ctrl.teclando || ctrl.load) return true;
          if (event == '2') {
            ctrl.escutaPad(event);
            return true;
          }
          return false;
        },
        child: Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent()
          },
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
                ctrl.escutaPad('2');
                return null;
              })
            },
            child: body(),
          ),
        ),
      );

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

  body() {
    return Center(
      child: FocusScope(
        node: ctrl.focusScope,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          // crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            txtNome(),
            if (ctrl.listUser.isNotEmpty) gridUsers(),
            if (ctrl.listUser.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text("Nada Encontrado.",
                    style: TextStyle(color: Colors.white, fontSize: 25)),
              ),
          ],
        ),
      ),
    );
  }

  final GlobalKey _textFieldKey = GlobalKey();
  txtNome() {
    final renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          // height: MediaQuery.of(context).size.height * 0.1,
          width: MediaQuery.of(context).size.width * 0.2,
          child: TextField(
            key: _textFieldKey,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                gapPadding: 3,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            focusNode: ctrl.txtFoco,
            readOnly: true,
            showCursor: false,

            onChanged: (str) => ctrl.escreveTxt(str),
            onTap: () => ctrl.txtSelecionado(""),
            // onFieldSubmitted: (str)=>ctrl.txtSelecionado(str),
            // onChanged: (str)=>ctrl.txtSelecionado(str),
            onSubmitted: (_) => ctrl.abrirBuscaTeclado(),
            onEditingComplete: () {},
            controller: ctrl.txtNome,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black),
          ),
        ),
        if (ctrl.txtFoco.hasFocus || ctrl.buscaFocos.hasFocus) ...[
          const SizedBox(width: 10),
          Focus(
            focusNode: ctrl.buscaFocos,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: ctrl.buscaFocos.hasFocus ? Colors.amber : Colors.white,
              ),
              margin: const EdgeInsets.only(top: 10, bottom: 3),
              width: (MediaQuery.of(context).size.width * 0.2) / 4,
              height: renderBox?.size.height,
              child: MaterialButton(
                onPressed: () {
                  if (ctrl.teclando) return;
                  ctrl.clickBtnBuscar();
                },
                child: const Icon(
                  Icons.search,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
        if (ctrl.teclando) ...[
          const SizedBox(width: 10),
          const Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.lock,
                  color: Colors.red,
                ),
              ),
              Text(
                "O / B",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 10),
              Text(
                "-  2x Para voltar a tela",
                style: TextStyle(color: Colors.white),
              )
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
            }),
      ),
    );
  }

  btnUser(int index) {
    const sdw = Shadow(color: Colors.black, blurRadius: 5);
    final foco = index == ctrl.selectedIndexGrid;
    final item = ctrl.listUser[index];
    return Container(
      foregroundDecoration: BoxDecoration(
        border: foco ? Border.all(color: Colors.amber, width: 3) : null,
      ),
      height: MediaQuery.of(context).size.height * 0.2,
      width: MediaQuery.of(context).size.width * 0.2,
      child: Focus(
        focusNode: ctrl.focusNodesGrid[index],
        onFocusChange: (value) {
          if (!ctrl.teclando && value) {
            ctrl.selectedIndexGrid = index;
            ctrl.attTela();
          }
        },
        child: GestureDetector(
          onTap: ctrl.teclando
              ? null
              : () => ctrl.clickPasta(
                    item.folderUrl.isNotEmpty ? item.folderUrl : item.title,
                  ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  cacheManager: WallpapercaveImageCache.manager,
                  httpHeaders: WallpapercaveImageCache.headers,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const ColoredBox(
                    color: Colors.black26,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF20242C),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 5),
                    color: Colors.black87,
                    child: Center(
                      child: SelectableText(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 5, top: 2),
                child: Icon(
                  Icons.folder,
                  color: Colors.white,
                  shadows: [sdw],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
