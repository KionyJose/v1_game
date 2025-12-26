// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Bando%20de%20Dados/db.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/Notificacao.dart';
import '../Metodos/leituraArquivo.dart';
import '../Modelos/Item.dart';
import 'MovimentoSistema.dart';

class PastaCtrl {
  DB db = DB();
  late BuildContext ctx;
  late final Function() attTela;

  
  String imgLoadPreview = "";
  String caminhoFinal = "";
  List<String> listCaminho = [];

  bool stateTela = false;
  bool load = true;
  bool loadArquivos = false;
      
  FocusScopeNode gridViewFocus1 = FocusScopeNode();
  FocusScopeNode gridViewFocus2 = FocusScopeNode();
  late FocusScopeNode focusScope;

  List<FocusNode> focusNodeSetas1 = List.generate(200, (index) => FocusNode());
  List<FocusNode> focusNodeSetas2 = List.generate(200, (index) => FocusNode());
  
  int selectedIndex1 = 0;  
  int selectedIndex2 = 0;

  LerArquivos lerArquivos = LerArquivos();
  List<String> unidades = [];
  List<Item> items = [];
  late Paad paad;




  PastaCtrl({required  this.ctx,  required this.attTela} ){
    iniciaTela();
    
  }
  
  disposeCtrl(){
    // paad.dispose();
    debugPrint("SAIU PASTA CTRL");
    // focoPrincipal.dispose();
    // for (var node in focusNodeIcones) {
    //   node.dispose();
    // }
    // listViewFocus.dispose();    
    // ctrlAnimeBgFundo.dispose();
  }

  iniciaEscutaPad()async {
      // Escutando mudanças no 'click' manualmente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      paad = Provider.of<Paad>(ctx, listen: false);
      paad.addListener(() => escutaPad(paad.click));
    });
  }
  bool entrei = false;

  iniciaTela()async { 
    if(entrei)return;
    iniciaEscutaPad();

    entrei = true;
    // Configuração inicial e carregamento de dados
    unidades = lerArquivos.getUnidadesWindows();
    caminhoFinal = "${unidades[0]}:";
    listCaminho.add(caminhoFinal);
    String caminhoDesktop = await lerArquivos.getDesktopPath();
    unidades.insert(0, caminhoDesktop); // "Área de Trabalho"
    items = await lerArquivos.lerNomesPasta(caminhoDesktop);
    listCaminho.add(caminhoDesktop);
  
    // Configura o foco inicial
    focusScope = gridViewFocus2; // Define qual grid terá foco inicial
    gridViewFocus2.requestFocus();
    requerirFoco();
    load = false;
    stateTela = true;
    attTela();
    
     
  }
  // late Paad paad;

  requerirFoco(){
    if (focusNodeSetas1.isNotEmpty && selectedIndex1 < focusNodeSetas1.length) {
      focusNodeSetas1[selectedIndex1].requestFocus(); // Foca no item inicial do Grid 1
    }
    if (focusNodeSetas2.isNotEmpty && selectedIndex2 < focusNodeSetas2.length) {
      focusNodeSetas2[selectedIndex2].requestFocus(); // Foca no item inicial do Grid 2
    }
  }

  caminhoExiste(){
    bool retorno;
    retorno = imgLoadPreview.isNotEmpty;
    if(retorno) retorno = File(imgLoadPreview).existsSync();
    return retorno;
  }

  selectItemDireito(bool hasFocus, int index){
    if (hasFocus) {
      selectedIndex2 = index;
      debugPrint('Item selecionado: ${items[index].nome}');
      String extencao = items[index].extencao.toUpperCase();
      if(extencao == "JPG"  || extencao == "PNG" ||  extencao == "JPEG"|| extencao == "WEBP"|| extencao == "GIF" || extencao == "BMP" ) {
        // Construir caminho completo para preview usando nome
        String caminhoBase = listCaminho.last;
        if(!caminhoBase.endsWith('\\')) {
          caminhoBase += '\\';
        }
        String nomeCompleto = items[index].nome;
        if(items[index].extencao.isNotEmpty) {
          nomeCompleto += '.${items[index].extencao}';
        }
        imgLoadPreview = caminhoBase + nomeCompleto;
        debugPrint('Preview imagem: $imgLoadPreview');
      }else{ 
        imgLoadPreview = "";
      }
      attTela();
    }
  }


  selectItemEsquerdo(bool hasFocus, int index) async {
    if (!hasFocus) return;
    
    String compare = caminhoFinal;
    selectedIndex1 = index;
    caminhoFinal = "${unidades[selectedIndex1]}${selectedIndex1==0 ? "" : ":"}";
    
    if(compare == caminhoFinal) return;
    
    debugPrint('Mudando para unidade: $caminhoFinal');
    
    // Inicia Busca Novos arquivos
    loadArquivos = true;
    attTela();
    
    try {
      items = await lerArquivos.lerNomesPasta(caminhoFinal);
      
      // Limpar histórico de caminhos e adicionar novo
      listCaminho.clear();
      listCaminho.add(caminhoFinal);
      
      selectedIndex2 = 0;
      
      if(ctx.mounted) {
        // Focar no primeiro item do grid direito
        if(focusNodeSetas2.isNotEmpty) {
          focusNodeSetas2[0].requestFocus();
        }
        attTela();
      }
    } catch(e) {
      debugPrint('Erro ao ler unidade: $e');
      Provider.of<Notificacao>(ctx, listen: false).notificarIn(Icons.error, 'Erro ao acessar unidade');
    } finally {
      loadArquivos = false;
      if(ctx.mounted) attTela();
    }
  }

  

  escutaPad(String event) async {
    if(!stateTela || load || event == "" || loadArquivos ) return;
      debugPrint("Click Paad PASSSTAAACTRLLL: $event  =======");
    try{
       MovimentoSistema.direcaoListView(focusScope, event);
    }catch(_){}
    if(event == "START"){//START
      // btnMais();
    }
    else if(event == "2"){//Entrar
      await btnEntrar();
    }
    else if(event == "3"){//Sair
      await clickVoltar();
    }
    else if(event == "LB"){// esquerda
      gridViewFocus1.requestFocus();
      focusScope = gridViewFocus1;
    }
    else if(event == "RB"){// Direita
      gridViewFocus2.requestFocus();
      focusScope = gridViewFocus2;
    }
    attTela();
  }

   btnEntrar() async {
    try{
      if(focusScope == gridViewFocus1){ // UNIDADES 
        focusScope = gridViewFocus2;
        selectedIndex2 = 0;
        return requerirFoco();
      }
      else if(focusScope == gridViewFocus2){ // PASTAS E ARQUIVOS Navegação
        
        if(!items[selectedIndex2].pasta){ // ARQUIVO Selecionado!
          loadArquivos = true;
          stateTela = false;

          // Construir caminho completo usando o nome do item
          String caminhoBase = listCaminho.last;
          if(!caminhoBase.endsWith('\\')) {
            caminhoBase += '\\';
          }
          String caminhoCompleto = caminhoBase + items[selectedIndex2].nome;
          if(items[selectedIndex2].extencao.isNotEmpty) {
            caminhoCompleto += '.${items[selectedIndex2].extencao}';
          }
          
          return Navigator.pop(
            ctx,
            [
              "caminho",
              caminhoCompleto,
              ""
            ]);
        }
        else{ // PASTA Selecionada - Entrar na pasta
          loadArquivos = true;
          attTela();
          
          // Construir caminho completo usando apenas o nome da pasta
          String caminhoBase = listCaminho.last;
          if(!caminhoBase.endsWith('\\')) {
            caminhoBase += '\\';
          }
          String novoCaminho = caminhoBase + items[selectedIndex2].nome;
          
          debugPrint('Entrando na pasta: $novoCaminho');
          
          // Tentar ler a pasta usando método otimizado
          items = await lerArquivos.lerNomesPasta(novoCaminho);
          
          // Atualizar caminho final e histórico
          caminhoFinal = novoCaminho;
          if(caminhoFinal != listCaminho.last) {
            listCaminho.add(caminhoFinal);
          }
          
          selectedIndex2 = 0;
          loadArquivos = false;
          
          // Focar no primeiro item
          if(focusNodeSetas2.isNotEmpty) {
            focusNodeSetas2[0].requestFocus();
          }
          
          attTela();
        }
      }
    }catch(e){
      debugPrint('Erro ao entrar na pasta: $e');
      loadArquivos = false;
      Provider.of<Notificacao>(ctx, listen: false).notificarIn(Icons.error, 'Erro ao acessar: $e');
      attTela();
    }
  }
  clickVoltar() async {
    if(listCaminho.length <= 1) {
      // Está na raiz, sair da tela
      stateTela = false;
      return Navigator.pop(ctx);
    }
    
    // Remover caminho atual e voltar para o anterior
    listCaminho.removeLast();
    caminhoFinal = listCaminho.last;
    
    debugPrint('Voltando para: $caminhoFinal');
    
    loadArquivos = true;
    attTela();
    
    try {
      items = await lerArquivos.lerNomesPasta(caminhoFinal);
      selectedIndex2 = 0;
      
      // Focar no primeiro item
      if(focusNodeSetas2.isNotEmpty) {
        focusNodeSetas2[0].requestFocus();
      }
      
      attTela();
    } catch(e) {
      debugPrint('Erro ao voltar: $e');
      Provider.of<Notificacao>(ctx, listen: false).notificarIn(Icons.error, 'Erro ao voltar');
    } finally {
      loadArquivos = false;
      attTela();
    }
  }

  
}