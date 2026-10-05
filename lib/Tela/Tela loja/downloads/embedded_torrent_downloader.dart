import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    WebViewEnvironment? environment;
    try {
      progresso(const ProgressoTorrent('Preparando download dentro do app…'));
      if (await WebViewEnvironment.getAvailableVersion() == null) {
        throw StateError(
            'Instale o Microsoft Edge WebView2 Runtime para baixar dentro do app.');
      }
      final support = await getApplicationSupportDirectory();
      environment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
          userDataFolder: p.join(support.path, 'torrent-webview'),
        ),
      );
      final ctx = context();
      if (cancel.value || !ctx.mounted) throw StateError('Download cancelado.');
      final result = await showDialog<TorrentDownloadResult>(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => TorrentDownloadView(
          etapa: etapa,
          environment: environment!,
          cancel: cancel,
          progresso: progresso,
        ),
      );
      if (result?.path != null) return result!.path!;
      throw StateError(result?.error ?? 'Download cancelado.');
    } on PlatformException catch (error, stack) {
      debugPrint('Falha nativa ao criar o WebView2: $error\n$stack');
      throw StateError(
          'Não foi possível iniciar o navegador interno (WebView2). '
          'Detalhe: ${error.message ?? error.code}');
    } finally {
      _cancel = null;
      cancel.dispose();
      try {
        await environment?.dispose();
      } catch (error) {
        debugPrint('Não foi possível liberar o ambiente de download: $error');
      } finally {
        _busy = false;
      }
    }
  }
}
