// Estado do catálogo da aba Cinema: quem carrega, guarda e completa os
// títulos. A tela só lê daqui — nenhuma chamada de rede mora no desenho.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'tmdb_cine.dart';

class CinemaCatalogo extends ChangeNotifier {
  /// Uma instância por execução do app, mesmo se a aba for desmontada.
  static final CinemaCatalogo sessao = CinemaCatalogo();

  CinemaCatalogo({CineFonte? fonte, CineFonte Function()? reserva})
      : _fonte = fonte ?? TmdbFonte(),
        _reserva = reserva ?? FonteDemoCine.new;

  CineFonte _fonte;
  final CineFonte Function() _reserva;

  List<FaixaCine> _faixas = const [];
  List<FaixaCine> get faixas => _faixas;

  bool carregando = false;
  bool _pedido = false;
  bool _disposed = false;

  /// Verdadeiro quando o que está na tela é o catálogo de demonstração.
  bool get demonstracao => !_fonte.configurada;

  /// Motivo pelo qual a tela caiu na demonstração; nulo quando o TMDB
  /// respondeu.
  String? aviso;

  /// Guarda o resultado de [detalhar] por título, para abrir a mesma ficha
  /// duas vezes sem repetir a requisição.
  final Map<int, TituloCine> _detalhados = {};
  final Map<int, Future<TituloCine>> _emCurso = {};

  /// Primeira carga, pedida quando a aba aparece — e não no arranque do app,
  /// porque o PageView monta as quatro abas de uma vez e ninguém abriu o
  /// cinema ainda.
  Future<void> garantirCarga() async {
    if (_pedido) return;
    _pedido = true;
    await recarregar();
  }

  Future<void> recarregar() async {
    if (carregando || _disposed) return;
    _pedido = true;
    carregando = true;
    aviso = null;
    notifyListeners();

    try {
      _faixas = await _fonte.carregar();
    } on ErroCine catch (erro) {
      await _cairParaDemonstracao(erro.mensagem);
    } catch (erro) {
      await _cairParaDemonstracao('Falha inesperada ao carregar o catálogo. '
          '$erro');
    }

    carregando = false;
    if (!_disposed) notifyListeners();
  }

  /// A tela nunca fica vazia: sem chave, ou com o TMDB fora do ar, ela mostra
  /// o catálogo de demonstração e diz por quê.
  Future<void> _cairParaDemonstracao(String motivo) async {
    if (_fonte.configurada) {
      _fonte.dispose();
      _fonte = _reserva();
    }
    aviso = motivo;
    _detalhados.clear();
    try {
      _faixas = await _fonte.carregar();
    } catch (_) {
      _faixas = const [];
    }
  }

  /// Completa o título (sinopse longa, logo, trailer, onde assistir) e troca
  /// a versão curta dentro das faixas, para a grade e a ficha nunca
  /// discordarem.
  Future<TituloCine> detalhar(TituloCine titulo) {
    final pronto = _detalhados[titulo.id];
    if (pronto != null) return Future.value(pronto);
    return _emCurso[titulo.id] ??= _detalhar(titulo);
  }

  /// A versão já completa, se existir — para desenhar sem esperar o Future.
  TituloCine completo(TituloCine titulo) => _detalhados[titulo.id] ?? titulo;

  Future<TituloCine> _detalhar(TituloCine titulo) async {
    TituloCine resultado;
    try {
      resultado = await _fonte.detalhar(titulo);
    } catch (_) {
      // A ficha abre com o que a lista já trouxe; sem trailer, e só.
      resultado = titulo.copiaCom(detalhado: true);
    }
    _emCurso.remove(titulo.id);
    if (_disposed) return resultado;
    _detalhados[titulo.id] = resultado;
    _substituirNasFaixas(resultado);
    notifyListeners();
    return resultado;
  }

  void _substituirNasFaixas(TituloCine titulo) {
    _faixas = [
      for (final faixa in _faixas)
        FaixaCine(
          titulo: faixa.titulo,
          chamada: faixa.chamada,
          forma: faixa.forma,
          itens: [
            for (final item in faixa.itens)
              item.id == titulo.id && item.tipo == titulo.tipo ? titulo : item,
          ],
        ),
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    _fonte.dispose();
    super.dispose();
  }
}
