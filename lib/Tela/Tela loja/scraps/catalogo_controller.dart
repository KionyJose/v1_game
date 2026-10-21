import 'dart:async';

import 'package:flutter/foundation.dart';
import 'catalogo_scraper.dart';
import 'diagnostico_catalogo.dart';

class CatalogoController extends ChangeNotifier {
  final CatalogoScraper scraper;

  /// Grava a falha na máquina do cliente. Injetável para os testes não
  /// escreverem no disco do desenvolvedor.
  final Future<void> Function(DiagnosticoCatalogo) registrarFalha;

  CatalogoController(this.scraper,
      {Future<void> Function(DiagnosticoCatalogo)? registrarFalha})
      : registrarFalha = registrarFalha ?? _registroPadrao;

  static Future<void> _registroPadrao(DiagnosticoCatalogo d) => d.registrar();

  final List<JogoCatalogo> _jogos = [];
  List<JogoCatalogo> get jogos => List.unmodifiable(_jogos);
  Map<String, String> generos = {};
  String genero = '';
  String total = '';
  String? erro;

  /// Causa classificada da última falha, com código e detalhe técnico. Nulo
  /// quando a última tentativa deu certo.
  DiagnosticoCatalogo? diagnostico;

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

  /// Termo pesquisado no site; vazio quando a tela mostra o catálogo.
  String termo = '';

  Future<void> atualizar({String? filtroGenero}) async {
    if (carregando) return;
    genero = filtroGenero ?? genero;
    // Escolher um gênero volta ao catálogo: o site não cruza busca e filtro.
    termo = '';
    // A fonte monta o endereço: o nome do parâmetro e os campos obrigatórios
    // do endereço base são dela, não da tela.
    await _carregar(scraper.catalogoPorGenero(genero), reiniciar: true);
  }

  /// Pergunta ao site, em vez de filtrar o que já está em memória. Um termo
  /// vazio devolve a tela ao catálogo.
  Future<void> buscar(String texto) async {
    if (carregando) return;
    final procurado = texto.trim();
    if (procurado.isEmpty) {
      termo = '';
      await atualizar();
      return;
    }
    termo = procurado;
    genero = '';
    await _carregar(scraper.busca(procurado), reiniciar: true);
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
    diagnostico = null;
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
      // Fonte que não classificou a falha não fica sem diagnóstico: o cliente
      // precisa de um código para relatar em qualquer caminho de erro.
      final causa = e is ErroCatalogo && e.diagnostico != null
          ? e.diagnostico!
          : DiagnosticoCatalogo.de(e, endereco: uri);
      diagnostico = causa;
      erro = e is ErroCatalogo ? e.mensagem : causa.mensagem;
      // Gravar o log é melhor-esforço: disco cheio ou pasta sem permissão não
      // pode virar erro assíncrono solto nem apagar a mensagem da tela.
      unawaited(registrarFalha(causa).catchError(
          (Object falha) => debugPrint('Log da loja não gravado: $falha')));
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
