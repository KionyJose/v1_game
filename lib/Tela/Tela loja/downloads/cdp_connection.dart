import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Transporte do navegador dedicado ao app, nunca da sessão pessoal do usuário.
class CdpConnection {
  final WebSocket _socket;
  final _eventos = StreamController<Map<String, dynamic>>.broadcast();
  final _pendentes = <int, Completer<Map<String, dynamic>>>{};
  late final StreamSubscription<dynamic> _subscription;
  int _id = 0;
  bool _fechado = false;
  Stream<Map<String, dynamic>> get eventos => _eventos.stream;

  CdpConnection._(this._socket) {
    _subscription = _socket.listen((mensagem) {
      final data = jsonDecode(mensagem as String) as Map<String, dynamic>;
      if (data['id'] is int) {
        final pedido = _pendentes.remove(data['id']);
        if (pedido == null) return;
        if (data['error'] != null) {
          pedido.completeError(StateError(
              'Falha na comunicação com o navegador: ${data['error']}'));
        } else {
          pedido.complete(
              (data['result'] as Map?)?.cast<String, dynamic>() ?? {});
        }
      } else if (!_eventos.isClosed) {
        _eventos.add(data);
      }
    }, onDone: _desconectado, onError: (Object _) => _desconectado());
  }

  static Future<CdpConnection> conectar(Uri uri) async =>
      CdpConnection._(await WebSocket.connect(uri.toString())
          .timeout(const Duration(seconds: 10)));

  Future<Map<String, dynamic>> enviar(String metodo,
      [Map<String, dynamic> parametros = const {}, String? sessao]) async {
    if (_fechado) throw StateError('A janela de download foi fechada.');
    final id = ++_id;
    final completer = Completer<Map<String, dynamic>>();
    _pendentes[id] = completer;
    _socket.add(jsonEncode({
      'id': id,
      'method': metodo,
      'params': parametros,
      if (sessao != null) 'sessionId': sessao
    }));
    try {
      return await completer.future.timeout(const Duration(seconds: 10));
    } finally {
      _pendentes.remove(id);
    }
  }

  void _desconectado() {
    _fechado = true;
    for (final pedido in _pendentes.values) {
      pedido.completeError(StateError('A janela de download foi fechada.'));
    }
    _pendentes.clear();
  }

  Future<void> fechar() async {
    _desconectado();
    await _subscription.cancel();
    await _socket.close();
    await _eventos.close();
  }
}
