import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../Interface/launcher_pad_scope.dart';
import '../../../System/app_storage.dart';
import '../scraps/diagnostico_catalogo.dart';
import '../scraps/jogo_detalhes.dart';
import 'arquivo_torrent.dart';
import 'torrent_download.dart';

class TorrentDownloadResult {
  const TorrentDownloadResult({this.path, this.error});
  final String? path;
  final String? error;
}

/// O JavaScript e o CAPTCHA pertencem ao site. Só a resposta liberada é capturada.
class TorrentDownloadView extends StatefulWidget {
  const TorrentDownloadView(
      {super.key,
      required this.etapa,
      required this.environment,
      required this.cancel,
      required this.progresso});
  final EtapaDownload etapa;
  final WebViewEnvironment environment;
  final ValueNotifier<bool> cancel;
  final void Function(ProgressoTorrent) progresso;

  @override
  State<TorrentDownloadView> createState() => _TorrentDownloadViewState();
}

class _TorrentDownloadViewState extends State<TorrentDownloadView> {
  InAppWebViewController? _web;
  Timer? _limit;
  bool _finished = false;
  bool _receiving = false;
  String _status = 'Carregando a etapa de download…';
  static const _maxBytes = 10 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    widget.cancel.addListener(_cancelled);
    _limit = Timer(
        const Duration(minutes: 10),
        () => _finish(const TorrentDownloadResult(
            error: 'O site não concluiu o download em 10 minutos. Se apareceu '
                'uma verificação, ela precisa ser concluída na própria '
                'janela.\n\nLOJA-WEBVIEW-TEMPO')));
  }

  @override
  void dispose() {
    _finished = true;
    _limit?.cancel();
    widget.cancel.removeListener(_cancelled);
    super.dispose();
  }

  void _cancelled() {
    if (widget.cancel.value && !_receiving) _finish(null);
  }

  void _finish(TorrentDownloadResult? result) {
    if (_finished || !mounted) return;
    _finished = true;
    _limit?.cancel();
    Navigator.of(context).pop(result);
  }

  void _progress(String message) {
    if (_finished || !mounted) return;
    setState(() => _status = message);
    widget.progresso(ProgressoTorrent(message));
  }

  Future<dynamic> _cdp(String method, [Map<String, dynamic>? parameters]) =>
      _web!
          .callDevToolsProtocolMethod(
              methodName: method, parameters: parameters)
          .timeout(const Duration(seconds: 25));

  Future<void> _created(InAppWebViewController web) async {
    _web = web;
    try {
      await web.addDevToolsProtocolEventListener(
        eventName: 'Fetch.requestPaused',
        callback: (data) => _response(data),
      );
      await _cdp('Fetch.enable', {
        'patterns': [
          {
            'urlPattern': widget.etapa.pagina.toString(),
            'requestStage': 'Response'
          },
        ]
      });
      if (!_finished) {
        await web.loadUrl(
            urlRequest:
                URLRequest(url: WebUri(widget.etapa.pagina.toString())));
      }
    } catch (erro) {
      // Sem o canal DevTools não há como capturar a resposta liberada.
      _finish(TorrentDownloadResult(
          error: 'Não foi possível preparar a captura do arquivo dentro do '
              'app. Confira o WebView2 Runtime.\n\nLOJA-WEBVIEW-DEVTOOLS\n'
              '${erro.runtimeType}: $erro'));
    }
  }

  Future<void> _response(dynamic raw) async {
    String? requestId;
    File? pending;
    try {
      final data = (raw is String ? jsonDecode(raw) : raw) as Map;
      requestId = data['requestId'] as String;
      final headers = <String, String>{
        for (final header in (data['responseHeaders'] as List? ?? []))
          (header['name'] as String).toLowerCase(): header['value'] as String,
      };
      final mime =
          headers['content-type']?.split(';').first.trim().toLowerCase();
      final url = (data['request'] as Map?)?['url'];
      if (_finished ||
          _receiving ||
          url != widget.etapa.pagina.toString() ||
          data['responseStatusCode'] != 200 ||
          mime != 'application/x-bittorrent') {
        await _cdp('Fetch.continueRequest', {'requestId': requestId});
        return;
      }
      _receiving = true;
      _limit?.cancel();
      if (widget.cancel.value) throw StateError('Download cancelado.');
      final length = int.tryParse(headers['content-length'] ?? '');
      if (length != null && (length < 10 || length > _maxBytes)) {
        throw StateError('O arquivo recebido tem tamanho inválido.');
      }
      _progress('Recebendo e validando o arquivo .torrent…');
      final rawBody =
          await _cdp('Fetch.getResponseBody', {'requestId': requestId});
      final body = (rawBody is String ? jsonDecode(rawBody) : rawBody) as Map;
      final encoded = body['body'] as String;
      if (encoded.length > ((_maxBytes + 2) ~/ 3) * 4) {
        throw StateError('O arquivo recebido ultrapassa o limite de 10 MB.');
      }
      final bytes = body['base64Encoded'] == true
          ? base64Decode(encoded)
          : latin1.encode(encoded);
      if (bytes.length < 10 || bytes.length > _maxBytes) {
        throw StateError('O arquivo recebido tem tamanho inválido.');
      }
      // Interrompe apenas a gravação do navegador; o arquivo será salvo pelo app.
      await _cdp('Fetch.failRequest',
          {'requestId': requestId, 'errorReason': 'Aborted'});
      requestId = null;
      final downloads = await getDownloadsDirectory();
      if (downloads == null) {
        throw StateError('Não foi possível localizar a pasta Downloads.');
      }
      final folder =
          await Directory(p.join(downloads.path, ArquivoTorrent.pasta))
              .create(recursive: true);
      await ensureWritableDirectory(folder);
      final id = 'v1-${DateTime.now().microsecondsSinceEpoch}';
      pending = File(p.join(folder.path, id));
      if (widget.cancel.value || _finished) {
        throw StateError('Download cancelado.');
      }
      await pending.writeAsBytes(bytes, flush: true);
      if (widget.cancel.value || _finished) {
        throw StateError('Download cancelado.');
      }
      final path =
          await ArquivoTorrent.confirmar(folder, id, widget.etapa.nomeArquivo);
      pending = null;
      _finish(TorrentDownloadResult(path: path));
    } catch (error) {
      if (requestId != null) {
        try {
          await _cdp('Fetch.failRequest',
              {'requestId': requestId, 'errorReason': 'Aborted'});
        } catch (_) {}
      }
      try {
        if (pending != null && await pending.exists()) await pending.delete();
      } catch (_) {/* Não substituir o erro original por falha de limpeza. */}
      // Cancelar é escolha do jogador, não defeito: não vira relatório.
      if (error is StateError && error.message.toString().contains('cancelado')) {
        _finish(TorrentDownloadResult(error: error.message.toString()));
        return;
      }
      // O tipo e a mensagem do erro eram jogados fora aqui, e qualquer falha
      // na captura — torrent inválido, pasta sem permissão, DevTools fora de
      // hora — chegava ao cliente como a mesma frase sem informação nenhuma.
      final causa = DiagnosticoCatalogo(
        falha: FalhaCatalogo.desconhecida,
        mensagem: error is StateError
            ? error.message.toString()
            : 'Não foi possível receber o arquivo .torrent dentro do app.',
        detalhe: 'Captura do .torrent — ${error.runtimeType}: $error',
        endereco: widget.etapa.pagina,
      );
      unawaited(causa.registrar());
      _finish(TorrentDownloadResult(
          error: '${causa.mensagem}\n\n${causa.codigo}\n${causa.detalhe}'));
    }
  }

  /// Traduz a falha do WebView2 para a mesma linguagem do catálogo.
  ///
  /// "Verifique sua conexão" cobria causas opostas: provedor bloqueando o
  /// domínio, proxy cortando HTTPS e site fora do ar pediam ações diferentes,
  /// e quem atende o cliente não tinha nada para trabalhar. Cada caso agora
  /// sai com código próprio e o detalhe técnico junto.
  static String _explicar(WebResourceError erro, Uri pagina) {
    final tipo = erro.type;
    final DiagnosticoCatalogo causa;
    if (tipo == WebResourceErrorType.HOST_LOOKUP) {
      causa = DiagnosticoCatalogo(
        falha: FalhaCatalogo.dnsBloqueado,
        mensagem: 'O navegador interno não encontrou o endereço do site. '
            'A rede bloqueia esse domínio para o WebView2, que resolve nomes '
            'pelo Windows. Teste pelo celular com 4G ou em outra rede.',
        detalhe: 'WebView2 HOST_NAME_NOT_RESOLVED: ${erro.description}',
        endereco: pagina,
      );
    } else if (tipo == WebResourceErrorType.TIMEOUT) {
      causa = DiagnosticoCatalogo(
        falha: FalhaCatalogo.tempoEsgotado,
        mensagem: 'O site não respondeu a tempo nesta etapa. Tente novamente.',
        detalhe: 'WebView2 TIMEOUT: ${erro.description}',
        endereco: pagina,
      );
    } else if (tipo == WebResourceErrorType.CANNOT_CONNECT_TO_HOST ||
        tipo == WebResourceErrorType.NOT_CONNECTED_TO_INTERNET ||
        tipo == WebResourceErrorType.NETWORK_CONNECTION_LOST) {
      causa = DiagnosticoCatalogo(
        falha: FalhaCatalogo.semRede,
        mensagem: 'O navegador interno não alcançou o site. Verifique se '
            'firewall ou antivírus não estão bloqueando o aplicativo.',
        detalhe: 'WebView2 ${tipo.toNativeValue()}: ${erro.description}',
        endereco: pagina,
      );
    } else {
      causa = DiagnosticoCatalogo(
        falha: FalhaCatalogo.desconhecida,
        mensagem: 'A etapa de download não carregou. Use o código abaixo ao '
            'relatar o problema.',
        detalhe: 'WebView2 ${tipo.toNativeValue()}: ${erro.description}',
        endereco: pagina,
      );
    }
    unawaited(causa.registrar());
    return '${causa.mensagem}\n\n${causa.codigo}\n${causa.detalhe}';
  }

  Future<void> _loaded(InAppWebViewController web, WebUri? url) async {
    if (_finished || url?.toString() != widget.etapa.pagina.toString()) return;
    try {
      final submitted = await web.evaluateJavascript(source: '''(() => {
        const form = document.querySelector('[data-download-form]');
        if (!form || window.__v1Submitted) return false;
        window.__v1Submitted = true;
        form.requestSubmit();
        return true;
      })()''');
      if (submitted == true) {
        _progress(
            'Preparando arquivo. Se o site pedir verificação, conclua abaixo.');
      } else {
        _progress('Conclua a etapa de download do site abaixo.');
      }
    } catch (_) {
      _progress('Use o botão do site abaixo para continuar o download.');
    }
  }

  @override
  Widget build(BuildContext context) => LauncherPadScope(
        menu: false,
        onCommand: (command) {
          if (command == 'START' || command == '3') {
            widget.cancel.value = true;
            return true;
          }
          return false;
        },
        child: PopScope(
          canPop: !_receiving,
          child: Dialog(
            insetPadding: const EdgeInsets.all(24),
            child: SizedBox(
              width: 1000,
              height: MediaQuery.sizeOf(context).height * .85,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Expanded(child: Text(_status)),
                      TextButton(
                          onPressed: () => widget.cancel.value = true,
                          child: const Text('Cancelar')),
                    ])),
                const Divider(height: 1),
                Expanded(
                    child: InAppWebView(
                  webViewEnvironment: widget.environment,
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useShouldOverrideUrlLoading: true,
                    supportMultipleWindows: false,
                  ),
                  onWebViewCreated: _created,
                  onPermissionRequest: (_, request) async => PermissionResponse(
                      resources: request.resources,
                      action: PermissionResponseAction.DENY),
                  onLoadStop: _loaded,
                  shouldOverrideUrlLoading: (_, action) async {
                    if (action.isForMainFrame != true) {
                      return NavigationActionPolicy.ALLOW;
                    }
                    final url = action.request.url;
                    return url?.scheme == 'https' &&
                            url?.host == widget.etapa.pagina.host
                        ? NavigationActionPolicy.ALLOW
                        : NavigationActionPolicy.CANCEL;
                  },
                  onReceivedError: (_, request, error) {
                    if (!_receiving && request.isForMainFrame == true) {
                      _finish(TorrentDownloadResult(
                          error: _explicar(error, widget.etapa.pagina)));
                    }
                  },
                )),
              ]),
            ),
          ),
        ),
      );
}
