import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../scraps/cliente_loja.dart';
import '../scraps/jogo_detalhes.dart';
import 'torrent_download.dart';
import 'torrent_download_view.dart';

/// Executa o formulário oficial em WebView2, dentro da janela do launcher.
class EmbeddedTorrentDownloader implements TorrentDownloader {
  EmbeddedTorrentDownloader(this.context);
  final BuildContext Function() context;
  ValueNotifier<bool>? _cancel;
  static bool _busy = false;

  @override
  void cancelar() => _cancel?.value = true;

  /// Um resolvedor só para todo o aplicativo.
  ///
  /// Criar um a cada compra zerava o cache, e a Cloudflare devolve os dois
  /// endereços em ordem alternada: o IP escolhido mudava entre uma compra e
  /// outra, os argumentos do navegador mudavam junto, e a segunda compra
  /// morria em `ERROR_INVALID_STATE`.
  static final ResolvedorDoH _resolvedor = ResolvedorDoH();

  /// O ambiente do WebView2 vive enquanto o aplicativo viver.
  ///
  /// O processo do navegador é compartilhado e não morre junto com a janela;
  /// recriar o ambiente enquanto ele respira falha com `ERROR_INVALID_STATE`
  /// — "o grupo ou recurso não está no estado correto". Então cria-se uma vez
  /// e reaproveita-se, que é o que a própria documentação do WebView2 pede.
  static WebViewEnvironment? _ambiente;
  static String? _argumentosEmUso;

  static Future<WebViewEnvironment> _ambienteDoApp(String host) async {
    final argumentos = await _regraDeResolucao(host);
    final existente = _ambiente;
    if (existente != null) {
      if (argumentos == _argumentosEmUso) return existente;
      // Mudar de argumento exige um processo novo, e o antigo ainda está de
      // pé. Reaproveitar é melhor que recusar a compra: o mapeamento anterior
      // continua valendo, porque o IP de borda da Cloudflare é estável.
      debugPrint('WebView2: mantendo o ambiente atual; os argumentos mudaram '
          'de "$_argumentosEmUso" para "$argumentos".');
      return existente;
    }
    final support = await getApplicationSupportDirectory();
    final ambiente = await WebViewEnvironment.create(
      settings: WebViewEnvironmentSettings(
        userDataFolder: p.join(support.path, 'torrent-webview'),
        // O WebView2 resolve DNS pelo Windows e não passa pelo contorno do
        // `ClienteDaLoja`: com o provedor bloqueando o domínio, o catálogo
        // abria e o Comprar morria em HOST_NAME_NOT_RESOLVED. A regra do
        // Chromium troca só a resolução — Host e SNI continuam com o nome
        // original, então o certificado segue válido.
        additionalBrowserArguments: argumentos,
      ),
    );
    _ambiente = ambiente;
    _argumentosEmUso = argumentos;
    return ambiente;
  }

  /// Argumentos do Chromium que apontam [host] para o IP achado por DoH.
  ///
  /// Só entram quando o contorno já está ligado — ou seja, quando o DNS do
  /// provedor falhou de verdade. Com DNS saudável o WebView2 segue normal.
  /// Nulo em qualquer falha: é melhor tentar e ver o erro do site do que
  /// recusar a compra por causa de um resolvedor fora do ar.
  static Future<String?> _regraDeResolucao(String host) async {
    if (!ClienteDaLoja.contornoAtivo.value) return null;
    try {
      return mapeamentoDeHost(host, await _resolvedor.resolver(host));
    } catch (erro) {
      debugPrint('Não foi possível mapear $host para o WebView2: $erro');
      return null;
    }
  }

  /// Monta o argumento do Chromium a partir dos endereços resolvidos.
  ///
  /// Precisa ser **determinístico**: o mesmo conjunto de endereços, em
  /// qualquer ordem, tem de gerar o mesmo texto. Um DNS com round-robin
  /// devolve a lista embaralhada a cada consulta, e argumento diferente entre
  /// uma compra e outra derruba a criação do ambiente com `ERROR_INVALID_STATE`.
  @visibleForTesting
  static String? mapeamentoDeHost(String host, List<String> ips) {
    if (ips.isEmpty) return null;
    final escolhido = (List<String>.of(ips)..sort()).first;
    debugPrint('WebView2: apontando $host para $escolhido');
    return '--host-resolver-rules="MAP $host $escolhido"';
  }

  @override
  Future<String> baixar(
      EtapaDownload etapa, void Function(ProgressoTorrent) progresso) async {
    if (!Platform.isWindows) {
      throw StateError('O download integrado está disponível no Windows.');
    }
    if (etapa.pagina.scheme != 'https' ||
        etapa.pagina.host != 'www.gamestorrents.app' ||
        !RegExp(r'^/pt-br/download/[a-f0-9]{32}/$')
            .hasMatch(etapa.pagina.path)) {
      throw StateError('Página de download inválida.');
    }
    if (_busy) throw StateError('Já existe um download em andamento.');
    _busy = true;
    final cancel = ValueNotifier(false);
    _cancel = cancel;
    WebViewEnvironment environment;
    try {
      progresso(const ProgressoTorrent('Preparando download dentro do app…'));
      if (await WebViewEnvironment.getAvailableVersion() == null) {
        throw StateError(
            'Instale o Microsoft Edge WebView2 Runtime para baixar dentro do app.');
      }
      environment = await _ambienteDoApp(etapa.pagina.host);
      final ctx = context();
      if (cancel.value || !ctx.mounted) throw StateError('Download cancelado.');
      final result = await showDialog<TorrentDownloadResult>(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => TorrentDownloadView(
          etapa: etapa,
          environment: environment,
          cancel: cancel,
          progresso: progresso,
        ),
      );
      if (result?.path != null) return result!.path!;
      throw StateError(result?.error ?? 'Download cancelado.');
    } on PlatformException catch (error, stack) {
      debugPrint('Falha nativa ao criar o WebView2: $error\n$stack');
      final detalhe = error.message ?? error.code;
      // `ERROR_INVALID_STATE` é o processo do navegador anterior ainda de pé
      // com outras opções. O ambiente guardado não serve mais; soltá-lo deixa
      // a próxima tentativa criar um limpo em vez de repetir a mesma falha.
      if (detalhe.contains('estado correto') ||
          detalhe.contains('INVALID_STATE') ||
          detalhe.contains('correct state')) {
        _ambiente = null;
        _argumentosEmUso = null;
        throw StateError(
            'O navegador interno ficou preso de uma tentativa anterior. '
            'Tente comprar de novo; se insistir, feche e abra o launcher.\n\n'
            'LOJA-WEBVIEW-ESTADO\n$detalhe');
      }
      throw StateError(
          'Não foi possível iniciar o navegador interno (WebView2).\n\n'
          'LOJA-WEBVIEW\n$detalhe');
    } finally {
      _cancel = null;
      cancel.dispose();
      // O ambiente não é descartado: ele vive enquanto o aplicativo viver.
      // Descartá-lo aqui era o que deixava a compra seguinte sem processo em
      // estado válido.
      _busy = false;
    }
  }
}
