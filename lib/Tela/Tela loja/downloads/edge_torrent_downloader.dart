import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../scraps/jogo_detalhes.dart';
import 'arquivo_torrent.dart';
import 'cdp_connection.dart';
import 'torrent_download.dart';

/// Executa o JavaScript oficial numa instância Edge exclusiva deste download.
/// A verificação hCaptcha permanece visível e é realizada pelo usuário.
class EdgeTorrentDownloader implements TorrentDownloader {
  final Future<Directory?> Function() _localizarDownloads;
  final Future<CdpConnection> Function()? _conectarNavegador;
  EdgeTorrentDownloader(
      {Future<Directory?> Function()? localizarDownloads,
      Future<CdpConnection> Function()? conectarNavegador})
      : _localizarDownloads = localizarDownloads ?? getDownloadsDirectory,
        _conectarNavegador = conectarNavegador;
  static bool _ocupado = false;
  bool _cancelado = false;
  CdpConnection? _cdp;

  static String _edge() {
    for (final root in [
      Platform.environment['ProgramFiles(x86)'],
      Platform.environment['ProgramFiles'],
      Platform.environment['LOCALAPPDATA']
    ]) {
      if (root == null) continue;
      final exe =
          p.join(root, 'Microsoft', 'Edge', 'Application', 'msedge.exe');
      if (File(exe).existsSync()) return exe;
    }
    throw StateError(
        'Microsoft Edge não encontrado. Instale o Edge para baixar pelo app.');
  }

  void _verificarCancelamento() {
    if (_cancelado) throw StateError('Download cancelado.');
  }

  @override
  void cancelar() {
    _cancelado = true;
  }

  @override
  Future<String> baixar(
      EtapaDownload etapa, void Function(ProgressoTorrent) progresso) async {
    if (!Platform.isWindows) {
      throw StateError('O download integrado está disponível no Windows.');
    }
    if (_ocupado) throw StateError('Já existe um download em andamento.');
    if (etapa.pagina.scheme != 'https' ||
        etapa.pagina.host != 'www.gamestorrents.app' ||
        !RegExp(r'^/pt-br/download/[a-f0-9]{32}/$')
            .hasMatch(etapa.pagina.path)) {
      throw StateError('Página de download inválida.');
    }
    _ocupado = true;
    _cancelado = false;
    StreamSubscription<Map<String, dynamic>>? eventos;
    Directory? perfil;
    String? guid;
    String? nome;
    bool concluido = false;
    String? erro;
    try {
      final downloads = await _localizarDownloads();
      if (downloads == null) {
        throw StateError('Não foi possível localizar a pasta Downloads.');
      }
      final destino =
          await Directory(p.join(downloads.path, ArquivoTorrent.pasta))
              .create(recursive: true);
      progresso(ProgressoTorrent('Destino: ${destino.path}'));
      final CdpConnection cdp;
      if (_conectarNavegador != null) {
        cdp = await _conectarNavegador!();
      } else {
        perfil = await Directory.systemTemp.createTemp('v1-torrent-edge-');
        final processo = await Process.start(_edge(), [
          '--user-data-dir=${perfil.path}',
          '--remote-debugging-port=0',
          '--remote-debugging-address=127.0.0.1',
          '--no-first-run',
          '--no-default-browser-check',
          '--app=about:blank',
        ]);
        processo.stdout.drain<void>();
        processo.stderr.drain<void>();
        final portaFile = File(p.join(perfil.path, 'DevToolsActivePort'));
        final inicio = DateTime.now();
        List<String> porta = [];
        while (
            DateTime.now().difference(inicio) < const Duration(seconds: 25)) {
          _verificarCancelamento();
          if (await portaFile.exists()) {
            porta = await portaFile.readAsLines();
            if (porta.length >= 2 && int.tryParse(porta.first) != null) break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
        if (porta.length < 2) {
          throw StateError('O Edge não iniciou a janela de download.');
        }
        cdp = await CdpConnection.conectar(
            Uri.parse('ws://127.0.0.1:${porta[0]}${porta[1]}'));
      }
      _cdp = cdp;
      eventos = cdp.eventos.listen((evento) {
        final data = (evento['params'] as Map?)?.cast<String, dynamic>() ?? {};
        if (evento['method'] == 'Browser.downloadWillBegin') {
          final url = data['url'] as String? ?? '';
          final sugerido = data['suggestedFilename'] as String? ?? '';
          if (guid == null &&
              sugerido == etapa.nomeArquivo &&
              (url.startsWith('blob:https://www.gamestorrents.app/') ||
                  url.startsWith('https://www.gamestorrents.app/'))) {
            guid = data['guid'] as String;
            nome = sugerido;
          } else {
            cdp.enviar('Browser.cancelDownload',
                {'guid': data['guid']}).catchError((_) => <String, dynamic>{});
          }
        }
        if (evento['method'] == 'Browser.downloadProgress' &&
            guid != null &&
            data['guid'] == guid) {
          final total = (data['totalBytes'] as num?)?.toDouble() ?? 0;
          final recebido = (data['receivedBytes'] as num?)?.toDouble() ?? 0;
          if (data['state'] == 'completed') {
            concluido = true;
          } else if (data['state'] == 'canceled') {
            erro = 'O navegador cancelou o download.';
          } else {
            progresso(ProgressoTorrent('Recebendo arquivo .torrent…',
                fracao: total > 0 ? (recebido / total).clamp(0, 1) : null));
          }
        }
      });
      await cdp.enviar('Browser.setDownloadBehavior', {
        'behavior': 'allowAndName',
        'downloadPath': destino.path,
        'eventsEnabled': true,
      });
      List<Map> paginas = [];
      for (var tentativa = 0; tentativa < 40; tentativa++) {
        _verificarCancelamento();
        final targets = await cdp.enviar('Target.getTargets');
        paginas = (targets['targetInfos'] as List)
            .cast<Map>()
            .where((t) => t['type'] == 'page')
            .toList();
        if (paginas.isNotEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (paginas.length != 1) {
        throw StateError(
            'Não foi possível selecionar a janela exclusiva do download.');
      }
      final anexo = await cdp.enviar('Target.attachToTarget',
          {'targetId': paginas.single['targetId'], 'flatten': true});
      final sessao = anexo['sessionId'] as String;
      await cdp.enviar('Page.enable', {}, sessao);
      await cdp.enviar(
          'Page.navigate', {'url': etapa.pagina.toString()}, sessao);
      bool enviado = false;
      String? ultimaMensagem;
      final limite = DateTime.now().add(const Duration(minutes: 10));
      while (!concluido && DateTime.now().isBefore(limite)) {
        _verificarCancelamento();
        if (erro != null) throw StateError(erro!);
        final resposta = await cdp.enviar(
            'Runtime.evaluate',
            {
              'expression': '''(() => {
            if (document.readyState !== 'complete') return {estado:'carregando'};
            if (location.href !== ${_literal(etapa.pagina.toString())}) return {estado:'carregando'};
            const form = document.querySelector('[data-download-form]');
            if (!form) return {estado:document.readyState === 'complete' ? 'invalida' : 'carregando'};
            const error = document.querySelector('[data-download-error]');
            if (error && !error.hidden && error.textContent.trim()) return {estado:'erro', mensagem:error.textContent.trim()};
            const captcha = document.querySelector('[data-captcha-area]');
            if (captcha && !captcha.hidden) return {estado:'captcha'};
            return {estado:'pronta'};
          })()''',
              'returnByValue': true,
            },
            sessao);
        final valor = (resposta['result'] as Map?)?['value'] as Map?;
        final estado = valor?['estado'];
        if (estado == 'erro') {
          throw StateError(valor?['mensagem'] as String? ??
              'O site não liberou o download.');
        }
        if (estado == 'invalida') {
          throw StateError(
              'A página de download mudou ou foi bloqueada pelo site.');
        }
        if (estado == 'pronta' && !enviado) {
          // requestSubmit dispara o manipulador original, incluindo suas verificações.
          await cdp.enviar(
              'Runtime.evaluate',
              {
                'expression':
                    'document.querySelector("[data-download-form]").requestSubmit()',
                'returnByValue': true
              },
              sessao);
          enviado = true;
        }
        final mensagem = estado == 'captcha'
            ? 'Conclua a verificação na janela do Edge e clique em Continuar para o download.'
            : guid != null
                ? 'Recebendo arquivo .torrent…'
                : 'Preparando download no site…';
        if (mensagem != ultimaMensagem) {
          progresso(ProgressoTorrent(mensagem));
          ultimaMensagem = mensagem;
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      _verificarCancelamento();
      if (!concluido || guid == null || nome == null) {
        throw StateError(
            'O download não foi concluído em 10 minutos. Tente novamente.');
      }
      progresso(
          const ProgressoTorrent('Confirmando arquivo na pasta Downloads…'));
      return await ArquivoTorrent.confirmar(destino, guid!, nome!);
    } finally {
      await eventos?.cancel();
      final cdp = _cdp;
      _cdp = null;
      if (cdp != null) {
        try {
          await cdp.enviar('Browser.close');
        } catch (_) {/* Janela já fechada. */}
        await cdp.fechar();
      }
      if (perfil != null) {
        // Diretório retornado por createTemp, exclusivo desta instância.
        try {
          await perfil.delete(recursive: true);
        } catch (_) {/* O Edge pode ainda estar encerrando. */}
      }
      _ocupado = false;
    }
  }
}

// String literal JavaScript; não é interpolada em comando de shell.
String _literal(String valor) =>
    '"${valor.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
