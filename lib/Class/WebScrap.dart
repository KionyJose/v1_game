// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:v1_game/Modelos/ImgWebScrap.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;

import '../Modelos/videoYT.dart';

class WebScrap{
 
  
  // Função para pegar os links das imagens com base no nome do jogo
  static Future<List<dynamic>> buscaUsersWalpaperCave(String gameName) async {
    String content = '';
    List<ImgWebScrap> list = [];
    // Cria a URL de busca dinâmica para Wallpapercave
    final url = Uri.parse('https://wallpapercave.com/search?q=$gameName');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final document = html.parse(response.body);
      // Seleciona todas as tags <img> e filtra os links das imagens
      final arquivo = document.querySelectorAll('img');
      list = arquivo.map((e) {
        final title = e.attributes['alt'] ?? ''; // Extrair o título (se disponível)
        final imageUrl = e.attributes['src'] ?? ''; // Extrair o link da imagem
        final tipo = e.attributes['class']??""; // Extrai o Tipo

        return ImgWebScrap(title: title, imageUrl: imageUrl,tipo: tipo);
      }).where((data) => data.imageUrl.isNotEmpty && data.imageUrl.contains("https")).toList();

      if (list.isEmpty) content = 'Nenhuma imagem encontrada para "$gameName".';
      if (list.isNotEmpty) content = 'Imagens encontradas: ${list.length}';
        
    } else {
      content = 'Erro ao buscar dados.';     
    }
    return [content,list];
  }

  static Future<List<dynamic>> buscaImgsWalpaperCave(String gameId) async {
    String content = '';
    List<ImgWebScrap> list = [];
    final url = Uri.parse('https://wallpapercave.com/$gameId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final document = html.parse(response.body);
      // Seleciona todas as tags <img> e filtra os links das imagens
      final arquivo = document.querySelectorAll('img');
      list = arquivo.map((e) {
        ImgWebScrap imgDados =ImgWebScrap();
        // final title = e.attributes['alt'] ?? ''; // Extrair o título (se disponível)
        // String imageUrl = e.attributes['src'] ?? ''; // Extrair o link da imagem
        // final tipo = e.attributes['class']??""; // Extrai o Tipo
        // if(imageUrl.isNotEmpty) imageUrl = "https://wallpapercave.com/$imageUrl";
        imgDados.fromMapImgFinal(e.attributes);
        return imgDados;
      }).where((item) => item.imageUrl.isNotEmpty && item.tipo == "wimg" && !item.imageUrl.contains(".webm")).toList( );
      
      if (list.isEmpty) content = 'Nenhuma imagem encontrada para "$gameId".';
      if (list.isNotEmpty) content = 'Imagens encontradas: ${list.length}';

    } else {
        content = 'Erro ao buscar dados.';
    }
    return [content,list];
  }


  static Future<String> downloadImage(String imageUrl, String nomeGame) async {
    String msg = "";
    try {
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        String extencao = imageUrl.split('.').last;
        const  directoryPath = 'C:\\Users\\Public\\Pictures\\FundoGamesV1';
        String  filePath = '$directoryPath\\$nomeGame.$extencao';

        final directory = Directory(directoryPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }

        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        msg = filePath;
        debugPrint('Imagem salva em: $filePath');
      } else {
        msg = "Erro ao baixar a imagem. Código: ${response.statusCode}";
        debugPrint('Erro ao baixar a imagem. Código: ${response.statusCode}');
      }
    } catch (e) {
      msg = "Erro:: ao salvar a imagem: $e";
      debugPrint('Erro ao salvar a imagem: $e');
    }
    return msg;
  }



  static Future<List<VideoYT>> buscaVideosYT(String query, String nomeJogo) async {
    List<VideoYT> listVideosFinal = [];
    try{ 
      List<VideoYT> listVideos = [];    
      final url = 'https://www.youtube.com/results?search_query=$query';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final htmlContent = response.body;
        final videoMatches = RegExp(r'"title":{"runs":\[{"text":"([^"]+)"\}.*?"videoId":"([^"]+)"').allMatches(htmlContent);
            
        listVideos = videoMatches.map((match) {
          VideoYT video = VideoYT();
          final videoId = match.group(2)!;
          video.nomeGame = nomeJogo;
          video.titulo = match.group(1)!;
          video.urlVideo = 'https://www.youtube.com/watch?v=$videoId';
          video.capaG = 'https://img.youtube.com/vi/$videoId/0.jpg';
          return video;
        }).toList();

        
        
        
      } else {
        throw Exception('Falha ao carregar a página do YouTube');
      }
      listVideosFinal = limpaUrlsRepetidas(listVideos);
    }catch(e){debugPrint(e.toString());}
    

    return listVideosFinal;
  }

  static List<VideoYT> limpaUrlsRepetidas(List<VideoYT>listVideos){
    // Conjunto para armazenar URLs únicas
    Set<String> urlsVistas = {};

    // Filtra a lista original, mantendo apenas vídeos com URLs únicas
    List<VideoYT> listaFiltrada = listVideos.where((video) {
    // Tenta adicionar a URL ao conjunto. Se já existir, add retorna false.
    return urlsVistas.add(video.urlVideo);
    }).toList();

    // A lista filtrada agora contém apenas vídeos com URLs únicas
    debugPrint('Total de vídeos após remoção de duplicatas: ${listaFiltrada.length}');
    return listaFiltrada;
  }




}