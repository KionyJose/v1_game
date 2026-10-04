// ignore_for_file: file_names, unnecessary_null_comparison, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import '../../Interface/pad_keyboard.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Widgets/Pops/Pops.dart';
import 'package:v1_game/Widgets/VisualizadorImgWeb.dart';
import '../../Class/WebScrap.dart';
import '../../Modelos/ImgWebScrap.dart';

class SeletorImgCtrl with ChangeNotifier {
  late BuildContext ctx;
  attTela() => !_disposed && ctx.mounted ? notifyListeners() : null;
  FocusScopeNode focusScope = FocusScopeNode();
  FocusNode txtFoco = FocusNode();
  FocusNode buscaFocos = FocusNode();
  TextEditingController txtNome = TextEditingController();
  late String nome;
  String txtEscrita = "";

  bool load = true;
  bool stateTela = false;
  bool teclando = false;

  List<String> listComandos = [];
  List<ImgWebScrap> listUser = [];
  List<ImgWebScrap> listImgs = [];
  List<FocusNode> focusNodesGrid = [];
  int selectedIndexGrid = 0;
  ScrollController scrollGridCtrl = ScrollController();
  bool _disposed = false;
  int _searchRevision = 0;
  final Future<List<dynamic>?> Function(String) buscar;
  SeletorImgCtrl(this.ctx, this.nome,
      {Future<List<dynamic>?> Function(String)? buscar})
      : buscar = buscar ?? WebScrap.buscaUsersWalpaperCave {
    txtFoco.addListener(attTela);
    buscaFocos.addListener(attTela);
    iniciaTela(nome);
  }

  Future<void> iniciaTela(String nomeAux) async {
    if (_disposed) return;
    final revision = ++_searchRevision;
    load = true;
    stateTela = false;
    selectedIndexGrid = 0;
    alteraTxtNome(nomeAux);
    listUser = [];
    attTela();
    try {
      final words = nomeAux
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      while (words.isNotEmpty) {
        final query = words.join(' ');
        final result = await buscar(query);
        if (_disposed || revision != _searchRevision) return;
        if (result != null) {
          listUser = List<ImgWebScrap>.from(result[1] as List);
        }
        if (listUser.isNotEmpty) break;
        words.removeLast();
      }
    } catch (error) {
      debugPrint('Erro ao buscar imagens: $error');
    } finally {
      if (!_disposed && revision == _searchRevision) {
        final oldNodes = focusNodesGrid;
        focusNodesGrid = List.generate(listUser.length, (_) => FocusNode());
        load = false;
        stateTela = true;
        attTela();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final node in oldNodes) {
            node.dispose();
          }
          if (_disposed) return;
          if (focusNodesGrid.isEmpty) {
            txtFoco.requestFocus();
          } else {
            focusNodesGrid.first.requestFocus();
          }
        });
      }
    }
  }

  Future<void> abrirBuscaTeclado() async {
    if (teclando || _disposed || load) return;
    teclando = true;
    stateTela = false;
    attTela();
    try {
      final value = await abrirTecladoPad(ctx, texto: txtNome.text);
      if (_disposed || !ctx.mounted) return;
      if (value != null) {
        alteraTxtNome(value);
        await clickBtnBuscar();
      }
    } finally {
      if (!_disposed) {
        teclando = false;
        stateTela = true;
        _limparClickPad();
        attTela();
        if (!load) txtFoco.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _searchRevision++;
    txtFoco.dispose();
    buscaFocos.dispose();
    txtNome.dispose();
    focusScope.dispose();
    scrollGridCtrl.dispose();
    for (final node in focusNodesGrid) {
      node.dispose();
    }
    super.dispose();
  }

  alteraTxtNome(String str) {
    txtNome.text = str;
    txtEscrita = str;
  }

  void escreveTxt(String str) => txtEscrita = str;
  Future<void> txtSelecionado(String str) => abrirBuscaTeclado();

  Future<void> clickPasta(String str) async {
    if (_disposed || !stateTela || load) return;
    stateTela = false;
    load = true;
    attTela();
    try {
      final slug = str
          .replaceAll('™', '')
          .replaceAll(':', '')
          .replaceAll('?', '')
          .replaceAll('!', '')
          .replaceAll('&', 'and')
          .trim()
          .replaceAll(RegExp(r'\s+'), '-');
      final result = await WebScrap.buscaImgsWalpaperCave(slug);
      if (_disposed || !ctx.mounted) return;
      listImgs =
          result == null ? [] : List<ImgWebScrap>.from(result[1] as List);
      if (listImgs.isEmpty) {
        ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(const SnackBar(
            content: Text('Nenhuma imagem disponível nesta seleção.')));
        return;
      }
      final image = await Pops.popTela(ctx, VisualizadorImgWeb(list: listImgs));
      if (_disposed || !ctx.mounted) return;
      if (image != null) Navigator.of(ctx).pop(image);
    } catch (error) {
      if (!_disposed && ctx.mounted) {
        ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(
            content: Text('Não foi possível carregar as imagens: $error')));
      }
    } finally {
      if (!_disposed && ctx.mounted) {
        _limparClickPad();
        stateTela = true;
        load = false;
        attTela();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed && selectedIndexGrid < focusNodesGrid.length) {
            focusNodesGrid[selectedIndexGrid].requestFocus();
          }
        });
      }
    }
  }

  clickBtnBuscar() async {
    await iniciaTela(txtNome.text);
    // Desativa o uso do mouse;
    // Provider.of<Paad>(ctx, listen: false).ativaMouse( usarEstado: true,  estado: false);
  }

  keyPress(KeyEvent key) async {
    if (key is KeyDownEvent || key is KeyRepeatEvent) {
      // debugPrint("Teclado Press: ${key.logicalKey.debugName}");
      String event = MovimentoSistema.convertKeyBoard(key.logicalKey.keyLabel);
      // Evita que teclas físicas (Escape/Backspace) fechem o seletor
      if (event == "3") {
        // debugPrint("Ignorando evento de fechar vindo do teclado: ${key.logicalKey.debugName}");
        return;
      }
      if (event == "2" && teclando) {
        escutaPad('ENTER');
        attTela();
        return;
      }
      escutaPad(event);
      attTela();
    }
  }

  escutaPad(String event) async {
    try {
      if (!stateTela || event == "") return;
      if (teclando) {
        if (event == "ENTER") {
          clickBtnBuscar();
          return;
        }
        int total = 0;
        listComandos.insert(0, event);
        if (listComandos.length == 3) {
          listComandos.removeLast();
          if (listComandos[0] == '3') total++;
          if (listComandos[1] == '3') total++;
          if (total != 2) return;
          teclando = false;
        }
        return;
      }
      MovimentoSistema.direcaoListView(focusScope, event);

      if (event == "3") {
        stateTela = false;
        _limparClickPad();
        return Navigator.pop(ctx);
      } else if (event == "2") {
        if (buscaFocos.hasFocus) return await iniciaTela(txtNome.text);
        if (txtFoco.hasFocus) {
          await abrirBuscaTeclado();
          return;
        }
        _limparClickPad();
        if (listUser.isNotEmpty && selectedIndexGrid < listUser.length) {
          clickPasta(listUser[selectedIndexGrid].title);
        }
      }
      // debugPrint(" ===== Click Paad: => $event" );
    } catch (erro) {
      debugPrint("ERRO ESCUTA PAD CLICK$erro");
    }
    if (event == "HOME") {
      // home = true;
      // Provider.of<Paad>(ctx, listen: false).click = "";
      // debugPrint("Tela resetada");
      // iniciaTela();
      // Provider.of<Paad>(ctx, listen: false).attTela();
    }

    Provider.of<Paad>(ctx, listen: false).click = "";
    Provider.of<Paad>(ctx, listen: false).attTela();
  }

  void _limparClickPad({int delayMs = 350}) {
    try {
      final paad = Provider.of<Paad>(ctx, listen: false);
      paad.click = "";
      paad.delay = true;
      paad.attTela();
      Timer(Duration(milliseconds: delayMs), () => paad.delay = false);
    } catch (_) {}
  }
}
