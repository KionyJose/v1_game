// ignore_for_file: avoid_print
// Sonda manual: reproduz o DNS bloqueado do cliente e confere o contorno.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/cliente_loja.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_detalhes_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_scraper.dart';

/// Faz o caminho normal falhar exatamente como o provedor do cliente faz.
class DnsBloqueado extends http.BaseClient {
  int tentativas = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    tentativas++;
    throw http.ClientException(
        'Failed host lookup: ${request.url.host}', request.url);
  }
}

void main() {
  final ligado = Platform.environment['RUN_LOJA_LIVE_PROBE'] == '1';

  test('Com o DNS bloqueado, o catálogo carrega pelo contorno', () async {
    ClienteDaLoja.contornoAtivo.value = false;
    final normal = DnsBloqueado();
    final cliente = ClienteDaLoja(direto: normal);
    final catalogo = GamesTorrentsScraper(client: cliente);
    final detalhes = GamesTorrentsDetalhesScraper(client: cliente);
    try {
      final pagina = await catalogo.carregar(catalogo.catalogo);
      print('CATALOGO: ${pagina.jogos.length} jogos | "${pagina.total}" '
          '| generos ${pagina.generos.length}');
      print('tentativas pelo caminho normal: ${normal.tentativas}');
      print('contorno ativo: ${ClienteDaLoja.contornoAtivo.value}');
      for (final j in pagina.jogos.take(3)) {
        print('  - ${j.nome}');
      }
      expect(pagina.jogos, isNotEmpty);
      expect(ClienteDaLoja.contornoAtivo.value, isTrue);

      final ficha = await detalhes.carregar(pagina.jogos.first.pagina);
      print('FICHA "${ficha.nome}": ${ficha.imagens.length} imagens, '
          '${ficha.versoes.length} versões');
      expect(ficha.nome, isNotEmpty);

      // A capa mora no mesmo domínio bloqueado: sem o contorno, cartão sem arte.
      final capa = pagina.jogos.firstWhere((j) => j.imagem != null).imagem!;
      final imagem = await cliente.get(capa);
      print('CAPA: HTTP ${imagem.statusCode} | ${imagem.bodyBytes.length} '
          'bytes | ${imagem.headers['content-type']}');
      expect(imagem.statusCode, 200);
      expect(imagem.bodyBytes.length, greaterThan(1000));

      final segunda = await catalogo.carregar(pagina.proxima!);
      print('PAGINA 2: ${segunda.jogos.length} jogos');
      // Depois da primeira troca ninguém mais bate no caminho bloqueado.
      print('tentativas finais pelo normal: ${normal.tentativas}');
      expect(normal.tentativas, 1);
    } on ErroCatalogo catch (e) {
      print('FALHOU: ${e.mensagem}');
      print(e.diagnostico?.relatorio ?? '');
      rethrow;
    } finally {
      catalogo.dispose();
      detalhes.dispose();
      ClienteDaLoja.contornoAtivo.value = false;
    }
  },
      skip: ligado ? false : 'Defina RUN_LOJA_LIVE_PROBE=1.',
      timeout: const Timeout(Duration(seconds: 180)));
}
