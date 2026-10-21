// ignore_for_file: avoid_print
// Sonda manual da Loja Interna contra o site ao vivo.
//
// Serve para reproduzir, na máquina do cliente, exatamente o que o aplicativo
// faz ao abrir a loja — e imprimir o diagnóstico classificado quando falha.
// Fica fora da suíte normal; exige RUN_LOJA_LIVE_PROBE=1.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_detalhes_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/steam_scraper.dart';

/// O site trata consultas seguidas como excesso e deixa algumas expirar.
Future<void> _pausa() => Future<void>.delayed(const Duration(seconds: 2));

void main() {
  final habilitado = Platform.environment['RUN_LOJA_LIVE_PROBE'] == '1';

  test('Loja Interna ao vivo', () async {
    final catalogo = GamesTorrentsScraper();
    final detalhes = GamesTorrentsDetalhesScraper();
    try {
      // Exatamente o endereço que CatalogoController.atualizar() monta.
      final uri = catalogo.catalogo.replace(queryParameters: const {});
      print('URI: $uri');
      final pagina = await catalogo.carregar(uri);
      print('CATALOGO: ${pagina.jogos.length} jogos | total "${pagina.total}" '
          '| generos ${pagina.generos.length}');
      print('PROXIMA: ${pagina.proxima}');
      for (final jogo in pagina.jogos.take(3)) {
        print('  - ${jogo.nome}');
        print('    ${jogo.pagina}');
      }

      await _pausa();
      final primeiro = pagina.jogos.first;
      print('\nFICHA de "${primeiro.nome}"');
      final ficha = await detalhes.carregar(primeiro.pagina);
      print('  imagens: ${ficha.imagens.length} | trailers: '
          '${ficha.trailers.length} | versoes: ${ficha.versoes.length}');
      for (final versao in ficha.versoes) {
        print('   - ${versao.titulo}');
      }
    } on ErroCatalogo catch (erro) {
      // É este o caminho que interessa reproduzir na máquina do cliente.
      print('\n=== FALHOU ===');
      print('Mensagem na tela: ${erro.mensagem}');
      final causa = erro.diagnostico;
      if (causa == null) {
        print('(sem diagnóstico classificado)');
      } else {
        print(causa.relatorio);
      }
    } catch (erro, stack) {
      print('FALHA NÃO CLASSIFICADA: ${erro.runtimeType}: $erro');
      print(stack);
    } finally {
      catalogo.dispose();
      detalhes.dispose();
    }
  },
      skip: habilitado
          ? false
          : 'Defina RUN_LOJA_LIVE_PROBE=1 para consultar o site.',
      timeout: const Timeout(Duration(seconds: 180)));

  test('Descobrir (Steam) ao vivo', () async {
    final catalogo = SteamScraper();
    final detalhes = SteamDetalhesScraper();
    try {
      final uri = catalogo.catalogoPorGenero('');
      print('URI: $uri');
      final pagina = await catalogo.carregar(uri);
      print('CARROSSEL: ${pagina.jogos.length} jogos | total "${pagina.total}" '
          '| generos ${pagina.generos.length}');
      for (final jogo in pagina.jogos.take(3)) {
        print('  - ${jogo.nome} | ${jogo.genero}');
      }

      await _pausa();
      final primeiro = pagina.jogos.first;
      print('\nFICHA de "${primeiro.nome}"');
      final ficha = await detalhes.carregar(primeiro.pagina);
      print('  preco: "${ficha.preco}" | generos: ${ficha.generos}');
      print('  imagens: ${ficha.imagens.length} | urlLoja: ${ficha.urlLoja}');

      await _pausa();
      final filtrada = catalogo.catalogoPorGenero('19');
      final acao = await catalogo.carregar(filtrada);
      print('\nGENERO Ação -> ${acao.jogos.length} jogos | "${acao.total}"');
    } on ErroCatalogo catch (erro) {
      print('\n=== FALHOU ===');
      print('Mensagem na tela: ${erro.mensagem}');
      print(erro.diagnostico?.relatorio ?? '(sem diagnóstico)');
    } finally {
      catalogo.dispose();
      detalhes.dispose();
    }
  },
      skip: habilitado
          ? false
          : 'Defina RUN_LOJA_LIVE_PROBE=1 para consultar a loja.',
      timeout: const Timeout(Duration(seconds: 180)));
}
