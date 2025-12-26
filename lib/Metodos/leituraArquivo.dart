// ignore_for_file: file_names, unnecessary_null_comparison
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../Modelos/Item.dart';

class LerArquivos{

  leituraString(String linha) {
    if (linha.isEmpty || linha == "" || linha == " ") return;
    String str = "";
  
    List<String> listRow = [];
    for (int i = 0; i < linha.length; i++) {
      if (linha.substring(i, i + 1) == ";") {
        listRow.add(str);
        str = "";
      } else {
        str += linha.substring(i, i + 1);
      }
    }

    return listRow;
  }

  Future<String> getDesktopPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final userProfile = Directory(directory.parent.path); // Caminho do usuário
    String desktopPaths = "";
    if (userProfile == null) {
      throw Exception('Não foi possível determinar o caminho do perfil do usuário.');
    }

    // Tenta acessar "Desktop" no idioma EUA    
    desktopPaths = '${userProfile.path}\\Desktop'; // Adiciona 'Desktop'
    final desktopPath = Directory(desktopPaths);
    if (desktopPath.existsSync()) {
      return desktopPath.path;
    }

    // Tenta acessar "Desktop" no idioma PT-BR        
    desktopPaths = '${userProfile.path}\\Área de Trabalho'; // Adiciona 'Desktop'
    final areaDeTrabalhoPath = Directory(desktopPaths);
    if (areaDeTrabalhoPath.existsSync()) {
      return areaDeTrabalhoPath.path;
    }
    throw Exception('Não foi possível localizar a área de trabalho.');
  }

  String desktopPath() {
    if (Platform.isWindows) {
      // Obtém o valor da variável de ambiente %USERPROFILE%
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) return userProfile;
    }
    return "";
  }
  arquivoUrl(String path) async {
    String url = "";
        try{
        String conteudo = await File(path).readAsString();
        List<String> conteudos = conteudo.split('\n');
        for (var element in conteudos) { 
          if(element.contains("URL=")){
            url = element.substring(4,element.length-1);
          }
        }

        }catch(_){}
    return url;
  }

  // Método otimizado que retorna apenas NOMES dos items (pastas e arquivos)
  Future<List<Item>> lerNomesPasta(String diretorio) async {
    List<Item> items = [];
    List<Item> itemsP = [];
    List<Item> itemsA = [];

    try {
      // Obtendo apenas as entradas do diretório sem ler conteúdo
      final dir = Directory(diretorio);
      
      // Verificar se o diretório existe e é acessível
      if (!dir.existsSync()) {
        debugPrint('Diretório não existe: $diretorio');
        return items;
      }

      // listSync com followLinks: false evita seguir links simbólicos
      // e é mais rápido. Captura erros de permissão individual
      List<FileSystemEntity> entradas;
      try {
        entradas = dir.listSync(followLinks: false);
      } catch (e) {
        debugPrint('Erro de permissão ao acessar: $diretorio - $e');
        // Tenta com recursive: false explicitamente
        try {
          entradas = dir.listSync(recursive: false, followLinks: false);
        } catch (e2) {
          debugPrint('Acesso negado a: $diretorio');
          return items; // Retorna lista vazia se não conseguir acessar
        }
      }

      for (FileSystemEntity entrada in entradas) {
        try {
          Item it = Item();
          String nomeItem = entrada.path.split(Platform.pathSeparator).last;
          
          // Ignorar arquivos/pastas do sistema ocultas
          if (nomeItem.startsWith('.') || nomeItem.startsWith('\$')) {
            continue;
          }
          
          // Verificando se é um arquivo
          if (entrada is File) {
            String extensao = nomeItem.contains('.') ? nomeItem.split('.').last : '';
            String nomeSemExtensao = nomeItem.contains('.') 
                ? nomeItem.substring(0, nomeItem.length - extensao.length - 1)
                : nomeItem;
            // Armazena apenas o nome, não o caminho completo
            it.addArquivo(nomeItem, extensao, nomeSemExtensao, false);
            itemsA.add(it);
          }
          // Verificando se é uma Pasta
          else if (entrada is Directory) {
            // Armazena apenas o nome da pasta
            it.addPasta(nomeItem, nomeItem);
            itemsP.add(it);
          }
        } catch (e) {
          // Erro individual em um item - continua processando outros
          debugPrint('Erro ao processar item: $e');
        }
      }

      items.addAll(itemsP);
      items.addAll(itemsA);
    } catch (e) {
      debugPrint('Erro geral ao ler pasta $diretorio: $e');
    }

    return items;
  }

  Future<List<Item>> lerDadosPasta(String diretorio ) async {
    List<Item> items = [];
    List<Item> itemsP = [];
    List<Item> itemsA = [];
    // Obtendo a lista de entradas no diretório
    List<FileSystemEntity> entradas = Directory(diretorio).listSync();

    for (FileSystemEntity entrada in entradas) {
      Item it = Item();
      // Verificando se é um arquivo
      if (FileSystemEntity.typeSync(entrada.path) == FileSystemEntityType.file) {
        String url = await arquivoUrl(entrada.path);
        String nomeArquivo = entrada.path.split(Platform.pathSeparator).last;
        String extensao = nomeArquivo.split('.').last;
        String nomeSemExtensao = nomeArquivo.substring(0, nomeArquivo.length - extensao.length - 1);      
        it.addArquivo(url != "" ? url : nomeArquivo , extensao, nomeSemExtensao, url != "");      
        itemsA.add(it);
      }
      // Verificando se é uma Pasta
      else if (FileSystemEntity.typeSync(entrada.path) == FileSystemEntityType.directory) {
        String nomePasta = entrada.path.split(Platform.pathSeparator).last;
        it.addPasta(entrada.path, nomePasta);      
        itemsP.add(it);      
      }
    }
    items.addAll(itemsP);
    items.addAll(itemsA);
    return items;
  }

  // // Função para formatar o tamanho do arquivo em bytes para uma string mais legível
  // String _formatBytes(int bytes) {
  //   const suffixes = ["B", "KB", "MB", "GB", "TB"];
  //   int index = 0;
  //   double tamanho = bytes.toDouble();
  //   while (tamanho >= 1024 && index < suffixes.length - 1) {
  //     tamanho /= 1024;
  //     index++;
  //   }
  //   return '${tamanho.toStringAsFixed(2)} ${suffixes[index]}';
  // }

  List<String> getUnidadesWindows() {
    List<String> unidades = [];
    for (int i = 65; i <= 90; i++) {
      String letra = String.fromCharCode(i);
      String caminho = '$letra:\\';
      if (Directory(caminho).existsSync()) {
        unidades.add(letra);
      }
    }
    return unidades;
  }

  void discosDisponieis() {
     debugPrint('Diretórios nos discos locais:');
    List<String> unidades = getUnidadesWindows();
    for (String unidade in unidades) {
      debugPrint('\nDiretórios na unidade $unidade:');
      listarDiretorios(unidade);
    }
  }

  

void listarDiretorios(String unidade) {
  try {
    Directory dir = Directory('$unidade:\\');
    List<FileSystemEntity> entradas = dir.listSync();

    for (FileSystemEntity entrada in entradas) {
      if (entrada is Directory) {
        debugPrint('Diretório: ${entrada.path}');
        // Se desejar listar os diretórios internos, pode chamar listarDiretorios(entrada.path);
      }
    }
  } catch (e) {
    debugPrint('Erro ao acessar diretórios na unidade $unidade: $e');
  }
}
}