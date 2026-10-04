import 'package:flutter/foundation.dart';
import 'catalogo_scraper.dart';

class CatalogoController extends ChangeNotifier {
  final CatalogoScraper scraper;
  CatalogoController(this.scraper);

  final List<JogoCatalogo> _jogos = [];
  List<JogoCatalogo> get jogos => List.unmodifiable(_jogos);
  Map<String, String> generos = {};
  String genero = '';
  String total = '';
  String? erro;
  Uri? proxima;
  bool carregando = false;
  bool _disposed = false;
  Uri? _ultimaUri;
  bool _ultimaReiniciar = true;

  Future<void> tentarNovamente() async {
    if (!carregando && _ultimaUri != null) {
      await _carregar(_ultimaUri!, reiniciar: _ultimaReiniciar);
    }
  }

  Future<void> atualizar({String? filtroGenero}) async {
    if (carregando) return;
    genero = filtroGenero ?? genero;
    await _carregar(
        scraper.catalogo
            .replace(queryParameters: genero.isEmpty ? {} : {'genre': genero}),
        reiniciar: true);
  }

  Future<void> carregarMais() async {
    if (!carregando && proxima != null) {
      await _carregar(proxima!, reiniciar: false);
    }
  }

  Future<void> _carregar(Uri uri, {required bool reiniciar}) async {
    _ultimaUri = uri;
    _ultimaReiniciar = reiniciar;
    carregando = true;
    erro = null;
    notifyListeners();
    try {
      final pagina = await scraper.carregar(uri);
      if (_disposed) return;
      if (reiniciar) _jogos.clear();
      final vistos = _jogos.map((e) => e.pagina).toSet();
      _jogos.addAll(pagina.jogos.where((e) => vistos.add(e.pagina)));
      generos = pagina.generos;
      total = pagina.total;
      proxima = pagina.proxima;
    } catch (e) {
      if (_disposed) return;
      erro = e is ErroCatalogo
          ? e.mensagem
          : 'Não foi possível acessar o site. Verifique sua conexão e tente novamente.';
    } finally {
      if (!_disposed) {
        carregando = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    scraper.dispose();
    super.dispose();
  }
}
