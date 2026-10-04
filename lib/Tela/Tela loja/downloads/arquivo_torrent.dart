import 'dart:io';
import 'package:dtorrent_parser/dtorrent_parser.dart';
import 'package:path/path.dart' as p;

class ArquivoTorrent {
  static const pasta = 'games torrent compra';

  static String nomeSeguro(String nome) {
    var limpo = nome.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_').trim();
    limpo = limpo.replaceAll(RegExp(r'[. ]+$'), '');
    if (limpo.length > 160) limpo = limpo.substring(0, 160);
    if (limpo.isEmpty) limpo = 'download';
    if (RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\.|$)',
            caseSensitive: false)
        .hasMatch(limpo)) {
      limpo = '_$limpo';
    }
    return limpo.toLowerCase().endsWith('.torrent') ? limpo : '$limpo.torrent';
  }

  /// Somente o GUID confirmado pelo navegador é lido. Arquivos anteriores ou
  /// .crdownload nunca podem ser confundidos com o resultado desta compra.
  static Future<String> confirmar(
      Directory destino, String guid, String nome) async {
    if (!RegExp(r'^[A-Za-z0-9-]+$').hasMatch(guid)) {
      throw StateError('Identificador de download inválido.');
    }
    final arquivo = File(p.join(destino.path, guid));
    if (!await arquivo.exists()) {
      throw StateError(
          'O navegador concluiu, mas o arquivo não foi encontrado na pasta de destino.');
    }
    final tamanho = await arquivo.length();
    if (tamanho < 10 || tamanho > 10 * 1024 * 1024) {
      throw StateError(
          'O arquivo recebido não tem tamanho válido para torrent.');
    }
    try {
      await Torrent.parseFromFile(arquivo.path);
    } catch (_) {
      throw StateError('O arquivo recebido não é um torrent válido.');
    }
    final seguro = nomeSeguro(nome);
    var finalPath = p.join(destino.path, seguro);
    var numero = 1;
    while (await File(finalPath).exists()) {
      finalPath = p.join(destino.path,
          '${p.basenameWithoutExtension(seguro)} ($numero).torrent');
      numero++;
    }
    final salvo = await arquivo.rename(finalPath);
    if (!await salvo.exists() || await salvo.length() != tamanho) {
      throw StateError('Não foi possível confirmar o arquivo salvo.');
    }
    return salvo.path;
  }
}
