import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Resolve nomes por DNS-over-HTTPS, quando o DNS do provedor não resolve.
///
/// O bloqueio que aparece na máquina do cliente é no DNS: o provedor devolve
/// "host não encontrado" para o domínio da loja, embora o site esteja no ar e
/// alcançável. Perguntar o endereço por HTTPS a um resolvedor público é o
/// mesmo que todo navegador moderno já faz, e não exige nada do cliente.
class ResolvedorDoH {
  ResolvedorDoH({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// Dois resolvedores: se o provedor derrubar um, o outro ainda responde.
  static final servidores = [
    Uri.https('cloudflare-dns.com', '/dns-query'),
    Uri.https('dns.google', '/resolve'),
  ];

  final Map<String, _Resolucao> _cache = {};

  /// Endereços IPv4 de [nome], do cache quando ainda válido.
  Future<List<String>> resolver(String nome) async {
    final guardado = _cache[nome];
    if (guardado != null && !guardado.vencida) return guardado.ips;

    Object? ultimoErro;
    for (final servidor in servidores) {
      try {
        final ips = await _perguntar(servidor, nome);
        if (ips.isEmpty) continue;
        _cache[nome] = _Resolucao(ips, DateTime.now().add(_janelaDeCache));
        return ips;
      } catch (erro) {
        ultimoErro = erro;
      }
    }
    // Um cache vencido ainda é melhor que nenhum endereço: o IP de borda da
    // Cloudflare muda devagar, e sem isto uma falha momentânea do resolvedor
    // derrubaria a loja inteira.
    if (guardado != null) return guardado.ips;
    throw StateError('Nenhum resolvedor DNS-over-HTTPS respondeu por $nome'
        '${ultimoErro == null ? '' : ': $ultimoErro'}');
  }

  static const _janelaDeCache = Duration(minutes: 10);

  Future<List<String>> _perguntar(Uri servidor, String nome) async {
    final resposta = await _client.get(
        servidor.replace(queryParameters: {'name': nome, 'type': 'A'}),
        headers: const {'Accept': 'application/dns-json'}).timeout(
        const Duration(seconds: 10));
    if (resposta.statusCode != 200) {
      throw StateError('${servidor.host} respondeu HTTP '
          '${resposta.statusCode}');
    }
    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
    if (corpo is! Map) throw StateError('${servidor.host}: resposta inválida');
    return [
      for (final registro in (corpo['Answer'] as List? ?? const []))
        if (registro is Map && registro['type'] == 1)
          '${registro['data']}'.trim(),
    ].where((ip) => ip.isNotEmpty).toList();
  }

  void close() => _client.close();
}

class _Resolucao {
  _Resolucao(this.ips, this.vence);
  final List<String> ips;
  final DateTime vence;
  bool get vencida => DateTime.now().isAfter(vence);
}

/// Cliente HTTP que fala direto com o IP resolvido por DoH.
///
/// Não dá para resolver isso com `HttpClient.connectionFactory`: a fábrica
/// precisa devolver um socket **já seguro**, e as únicas formas públicas de
/// criar um `ConnectionTask<SecureSocket>` usam o mesmo argumento para
/// conectar e para o SNI. Apontando para o IP, o SNI vira o IP e o handshake
/// morre em `HANDSHAKE_FAILURE_ON_CLIENT_HELLO`, porque o certificado é de
/// `gamestorrents.app`. `SecureSocket.secure` aceita o `host` separado do
/// endereço, que é o que permite conectar no IP e apresentar o nome certo.
class ClienteDireto extends http.BaseClient {
  ClienteDireto({ResolvedorDoH? resolvedor, this.limiteDeCorpo = 16 << 20})
      : _resolvedor = resolvedor ?? ResolvedorDoH();

  final ResolvedorDoH _resolvedor;
  final int limiteDeCorpo;

  static const _maximoDeRedirecionamentos = 5;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _enviar(request, request.url, 0);

  Future<http.StreamedResponse> _enviar(
      http.BaseRequest original, Uri destino, int saltos) async {
    if (destino.scheme != 'https') {
      throw StateError('O contorno de DNS só atende HTTPS.');
    }
    final ips = await _resolvedor.resolver(destino.host);
    final resposta = await _pedir(original, destino, ips);

    final local = resposta.cabecalhos['location'];
    if (const [301, 302, 303, 307, 308].contains(resposta.status) &&
        local != null &&
        local.isNotEmpty) {
      if (saltos >= _maximoDeRedirecionamentos) {
        throw StateError('Redirecionamentos demais a partir de $destino.');
      }
      return _enviar(original, destino.resolve(local), saltos + 1);
    }

    return http.StreamedResponse(
      Stream.value(resposta.corpo),
      resposta.status,
      contentLength: resposta.corpo.length,
      request: original,
      headers: resposta.cabecalhos,
      reasonPhrase: resposta.motivo,
    );
  }

  Future<_Resposta> _pedir(
      http.BaseRequest original, Uri destino, List<String> ips) async {
    Object? ultimoErro;
    // Um IP de borda pode estar fora; os outros do mesmo nome continuam.
    for (final ip in ips) {
      Socket? cru;
      try {
        cru = await Socket.connect(ip, destino.port == 0 ? 443 : destino.port,
            timeout: const Duration(seconds: 15));
        // O `host` aqui é o SNI e o nome validado no certificado; o endereço
        // já foi escolhido acima. É o ponto inteiro deste cliente.
        final seguro = await SecureSocket.secure(cru, host: destino.host)
            .timeout(const Duration(seconds: 15));
        cru = null; // A posse passou para o socket seguro.
        try {
          return await _conversar(original, destino, seguro);
        } finally {
          await seguro.close().catchError((_) {});
          seguro.destroy();
        }
      } catch (erro) {
        ultimoErro = erro;
        cru?.destroy();
      }
    }
    throw ultimoErro ?? StateError('Nenhum endereço de ${destino.host} atendeu.');
  }

  Future<_Resposta> _conversar(
      http.BaseRequest original, Uri destino, SecureSocket socket) async {
    final corpoEnviado = original is http.Request ? original.bodyBytes : null;
    final caminho =
        destino.path.isEmpty ? '/' : destino.path + (destino.hasQuery ? '?${destino.query}' : '');

    final cabecalhos = <String, String>{
      'Host': destino.host,
      // Sem compressão e com a conexão fechada ao fim, o corpo termina no
      // EOF: não é preciso reimplementar gzip para ler uma página.
      'Accept-Encoding': 'identity',
      'Connection': 'close',
      ...original.headers,
    };
    if (corpoEnviado != null) {
      cabecalhos['Content-Length'] = '${corpoEnviado.length}';
    }

    final pedido = StringBuffer()
      ..write('${original.method} $caminho HTTP/1.1\r\n');
    cabecalhos.forEach((nome, valor) => pedido.write('$nome: $valor\r\n'));
    pedido.write('\r\n');

    socket.add(utf8.encode(pedido.toString()));
    if (corpoEnviado != null) socket.add(corpoEnviado);
    await socket.flush();

    final bytes = <int>[];
    await for (final pedaco in socket.timeout(const Duration(seconds: 30))) {
      bytes.addAll(pedaco);
      if (bytes.length > limiteDeCorpo) {
        throw StateError('Resposta de ${destino.host} passou do limite.');
      }
    }
    return _Resposta.analisar(bytes);
  }

  @override
  void close() {
    _resolvedor.close();
    super.close();
  }
}

class _Resposta {
  _Resposta(this.status, this.motivo, this.cabecalhos, this.corpo);
  final int status;
  final String motivo;
  final Map<String, String> cabecalhos;
  final Uint8List corpo;

  static final _fimDoCabecalho = [13, 10, 13, 10]; // \r\n\r\n

  static _Resposta analisar(List<int> bytes) {
    final corte = _procurar(bytes, _fimDoCabecalho);
    if (corte < 0) throw StateError('Resposta HTTP sem cabeçalho completo.');
    final linhas = utf8
        .decode(bytes.sublist(0, corte), allowMalformed: true)
        .split('\r\n');
    final inicial = linhas.first.split(' ');
    if (inicial.length < 2) throw StateError('Linha de status inválida.');
    final status = int.tryParse(inicial[1]);
    if (status == null) throw StateError('Status HTTP ilegível.');

    final cabecalhos = <String, String>{};
    for (final linha in linhas.skip(1)) {
      final divisor = linha.indexOf(':');
      if (divisor <= 0) continue;
      final nome = linha.substring(0, divisor).trim().toLowerCase();
      final valor = linha.substring(divisor + 1).trim();
      // Vários Set-Cookie viram uma linha só, como o pacote http faz.
      cabecalhos[nome] =
          cabecalhos.containsKey(nome) ? '${cabecalhos[nome]}, $valor' : valor;
    }

    var corpo = Uint8List.fromList(bytes.sublist(corte + 4));
    if ((cabecalhos['transfer-encoding'] ?? '').toLowerCase().contains(
        'chunked')) {
      corpo = _desfazerPedacos(corpo);
    } else {
      final tamanho = int.tryParse(cabecalhos['content-length'] ?? '');
      if (tamanho != null && tamanho < corpo.length) {
        corpo = Uint8List.sublistView(corpo, 0, tamanho);
      }
    }
    return _Resposta(status, inicial.skip(2).join(' '), cabecalhos, corpo);
  }

  /// Desfaz `Transfer-Encoding: chunked`.
  ///
  /// A Cloudflare usa chunked mesmo com `Connection: close`. Sem desfazer, os
  /// marcadores de tamanho entram no meio do HTML e corrompem o conteúdo em
  /// pontos espalhados — um estrago silencioso, que o parser de HTML engole.
  static Uint8List _desfazerPedacos(Uint8List cru) {
    final saida = <int>[];
    var i = 0;
    while (i < cru.length) {
      final fimDaLinha = _procurar(cru, const [13, 10], inicio: i);
      if (fimDaLinha < 0) break;
      final cabecalho = utf8
          .decode(cru.sublist(i, fimDaLinha), allowMalformed: true)
          .split(';')
          .first
          .trim();
      final tamanho = int.tryParse(cabecalho, radix: 16);
      if (tamanho == null) {
        throw StateError('Pedaço HTTP com tamanho inválido: "$cabecalho".');
      }
      i = fimDaLinha + 2;
      if (tamanho == 0) break;
      if (i + tamanho > cru.length) {
        throw StateError('Pedaço HTTP maior que a resposta recebida.');
      }
      saida.addAll(cru.sublist(i, i + tamanho));
      i += tamanho + 2; // pula o CRLF que fecha o pedaço
    }
    return Uint8List.fromList(saida);
  }

  static int _procurar(List<int> onde, List<int> oque, {int inicio = 0}) {
    for (var i = inicio; i <= onde.length - oque.length; i++) {
      var igual = true;
      for (var j = 0; j < oque.length; j++) {
        if (onde[i + j] != oque[j]) {
          igual = false;
          break;
        }
      }
      if (igual) return i;
    }
    return -1;
  }
}

/// O cliente que as telas da loja usam.
///
/// Tenta o caminho normal primeiro — é mais rápido e reaproveita conexão — e
/// só troca para o contorno quando o DNS do provedor falha. A troca é
/// lembrada pelo resto da sessão, para não pagar a falha a cada página.
/// O cliente não configura nada: isso acontece sozinho.
class ClienteDaLoja extends http.BaseClient {
  ClienteDaLoja({http.Client? direto, http.Client? contorno})
      : _normal = direto ?? IOClient(),
        _contorno = contorno ?? ClienteDireto();

  final http.Client _normal;
  final http.Client _contorno;

  /// Visível para a tela poder avisar que entrou pelo contorno.
  static final contornoAtivo = ValueNotifier<bool>(false);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (contornoAtivo.value) return _contorno.send(_copiar(request));
    try {
      return await _normal.send(request);
    } catch (erro) {
      if (!_pareceBloqueioDeDns(erro)) rethrow;
      debugPrint('DNS do provedor não resolveu ${request.url.host}; '
          'entrando pelo resolvedor DNS-over-HTTPS.');
      contornoAtivo.value = true;
      return _contorno.send(_copiar(request));
    }
  }

  /// Um `BaseRequest` já enviado não pode ser reenviado.
  http.BaseRequest _copiar(http.BaseRequest original) {
    final copia = http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;
    if (original is http.Request) copia.bodyBytes = original.bodyBytes;
    return copia;
  }

  static bool _pareceBloqueioDeDns(Object erro) {
    if (erro is SocketException) {
      return erro.osError?.errorCode == 11001 ||
          '$erro'.contains('Failed host lookup') ||
          '$erro'.contains('No address associated with hostname');
    }
    // O pacote http embrulha o SocketException e perde o tipo.
    return erro is http.ClientException &&
        erro.message.contains('Failed host lookup');
  }

  @override
  void close() {
    _normal.close();
    _contorno.close();
    super.close();
  }
}

/// Cache de imagens da loja que passa pelo mesmo cliente.
///
/// As capas moram no domínio bloqueado. O `CachedNetworkImage` tem a sua
/// própria pilha HTTP, que usa o DNS do sistema: sem isto o catálogo abria
/// pelo contorno e os cartões ficavam todos sem capa.
class CacheDaLoja {
  static CacheManager? _instancia;

  static CacheManager get instancia => _instancia ??= CacheManager(Config(
        'v1_loja_imagens',
        stalePeriod: const Duration(days: 7),
        fileService: HttpFileService(httpClient: ClienteDaLoja()),
      ));

  /// Usado pelos testes para injetar um cliente próprio.
  @visibleForTesting
  static set instancia(CacheManager valor) => _instancia = valor;
}
