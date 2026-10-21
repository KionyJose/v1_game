import 'dart:async';

import 'package:flutter/material.dart';

import '../../Controllers/SonsSistema.dart';
import '../../Interface/launcher_header.dart';
import '../../Interface/launcher_pad_scope.dart';
import '../../Interface/launcher_routes.dart';
import '../../Interface/pad_keyboard.dart';
import '../Tela loja/componentes/erro_catalogo_painel.dart';
import '../Tela loja/scraps/catalogo_controller.dart';
import '../Tela loja/scraps/catalogo_scraper.dart';
import '../Tela loja/scraps/jogo_detalhes.dart';
import '../Tela loja/scraps/steam_scraper.dart';
import 'descobrir_card.dart';
import 'descobrir_detalhes.dart';

/// Carrossel de descoberta: um jogo em destaque no centro, vizinhos de lado.
///
/// É uma tela de navegar olhando, não uma grade de procurar. Por isso o
/// carrossel manda: o cartão central é o selecionado, e esquerda/direita
/// movem a esteira em vez de mudar o foco de um widget para outro. Busca e
/// gêneros continuam acima, porque sem eles 300 mil jogos não têm serventia.
class DescobrirTela extends StatefulWidget {
  const DescobrirTela({
    super.key,
    this.scraper,
    this.detalhesScraper,
    this.sons = true,
  });

  final CatalogoScraper? scraper;
  final DetalhesScraper Function()? detalhesScraper;

  /// Desligado nos testes: o motor de áudio não sobe no ambiente de teste.
  final bool sons;

  @override
  State<DescobrirTela> createState() => _DescobrirTelaState();
}

class _DescobrirTelaState extends State<DescobrirTela> {
  late final CatalogoController _catalogo;
  late final PageController _pagina;

  /// Posição contínua da esteira, usada para escalar cada cartão. Vem do
  /// próprio controller a cada quadro, então o destaque acompanha o arrasto
  /// do mouse, e não só o fim da animação.
  double _posicao = 0;
  int _indice = 0;
  bool _tecladoAberto = false;
  bool _abrindo = false;

  final _buscaController = TextEditingController();
  final _buscaFocus = FocusNode();
  final _carrosselFocus = FocusNode(debugLabel: 'carrossel');

  static const _violeta = Color(0xFFB6A8FF);
  static const _fracaoViewport = .26;

  @override
  void initState() {
    super.initState();
    _catalogo = CatalogoController(widget.scraper ?? SteamScraper());
    _pagina = PageController(viewportFraction: _fracaoViewport)
      ..addListener(_acompanhar);
    _catalogo.addListener(_catalogoMudou);
    _catalogo.atualizar();
  }

  @override
  void dispose() {
    _pagina.removeListener(_acompanhar);
    _catalogo.removeListener(_catalogoMudou);
    _pagina.dispose();
    _catalogo.dispose();
    _buscaController.dispose();
    _buscaFocus.dispose();
    _carrosselFocus.dispose();
    super.dispose();
  }

  void _acompanhar() {
    if (!_pagina.hasClients || !_pagina.position.hasContentDimensions) return;
    final atual = _pagina.page ?? 0;
    if ((atual - _posicao).abs() < .001) return;
    setState(() => _posicao = atual);
  }

  /// Uma lista nova começa do primeiro jogo; sem isto o carrossel ficava
  /// preso numa página que a nova busca nem tem.
  void _catalogoMudou() {
    if (_catalogo.jogos.isEmpty && _indice != 0) {
      setState(() {
        _indice = 0;
        _posicao = 0;
      });
      if (_pagina.hasClients) _pagina.jumpToPage(0);
    }
  }

  void _som(void Function() tocar) {
    if (widget.sons) tocar();
  }

  void _irPara(int destino) {
    final jogos = _catalogo.jogos;
    if (jogos.isEmpty) return;
    final alvo = destino.clamp(0, jogos.length - 1);
    if (alvo == _indice) return;
    setState(() => _indice = alvo);
    _som(SonsSistema.futuristicMove);
    // Desaceleração suave: easeOutCubic chega devagar no lugar de travar.
    _pagina.animateToPage(alvo,
        duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    // Perto do fim, pede a próxima página antes de o usuário encostar nela.
    if (alvo >= jogos.length - 6) _carregarMais();
  }

  void _carregarMais() {
    if (!_catalogo.carregando && _catalogo.proxima != null) {
      unawaited(_catalogo.carregarMais());
    }
  }

  Future<void> _abrir() async {
    final jogos = _catalogo.jogos;
    if (_abrindo || jogos.isEmpty) return;
    _abrindo = true;
    _som(SonsSistema.futuristicOpen);
    try {
      await abrirTelaLauncher<void>(
          context,
          DescobrirDetalhes(
            jogo: jogos[_indice.clamp(0, jogos.length - 1)],
            scraper: widget.detalhesScraper?.call() ?? SteamDetalhesScraper(),
            sons: widget.sons,
          ));
    } finally {
      _abrindo = false;
      if (mounted) _carrosselFocus.requestFocus();
    }
  }

  Future<void> _teclado() async {
    if (_tecladoAberto) return;
    _tecladoAberto = true;
    final valor = await abrirTecladoPad(context, texto: _buscaController.text);
    _tecladoAberto = false;
    if (!mounted) return;
    if (valor != null) {
      _buscaController.text = valor;
      await _buscar();
      if (!mounted) return;
    }
    _buscaFocus.requestFocus();
  }

  Future<void> _buscar() async {
    setState(() {
      _indice = 0;
      _posicao = 0;
    });
    if (_pagina.hasClients) _pagina.jumpToPage(0);
    await _catalogo.buscar(_buscaController.text);
  }

  Future<void> _filtrar(String genero) async {
    _som(SonsSistema.click);
    setState(() {
      _indice = 0;
      _posicao = 0;
    });
    if (_pagina.hasClients) _pagina.jumpToPage(0);
    await _catalogo.atualizar(filtroGenero: genero);
  }

  bool _comando(String comando) {
    if (_buscaFocus.hasFocus) {
      if (comando == '2') {
        _teclado();
        return true;
      }
      if (comando == 'BAIXO') {
        _carrosselFocus.requestFocus();
        return true;
      }
      return false;
    }
    switch (comando) {
      case 'ESQUERDA':
        _irPara(_indice - 1);
        return true;
      case 'DIREITA':
        _irPara(_indice + 1);
        return true;
      case 'LB':
        _irPara(_indice - 10);
        return true;
      case 'RB':
        _irPara(_indice + 10);
        return true;
      case 'CIMA':
        _buscaFocus.requestFocus();
        return true;
      case '2':
        _abrir();
        return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => LauncherPadScope(
        revealInitialFocus: false,
        onCommand: _comando,
        child: Scaffold(
          backgroundColor: const Color(0xFF07060C),
          appBar: const LauncherHeader(title: Text('Descobrir')),
          body: AnimatedBuilder(
            animation: _catalogo,
            builder: (context, _) => SafeArea(
              child: Column(children: [
                _cabecalho(context),
                Expanded(child: _corpo(context)),
                _rodape(context),
              ]),
            ),
          ),
        ),
      );

  Widget _cabecalho(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 8),
        child: Column(children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: TextField(
                controller: _buscaController,
                focusNode: _buscaFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _buscar(),
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  hintText: 'Buscar na ${_catalogo.scraper.nome}'
                      ' · Enter para pesquisar',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                      tooltip: 'Teclado interno',
                      onPressed: _teclado,
                      icon: const Icon(Icons.keyboard_rounded)),
                  filled: true,
                  fillColor: const Color(0xFF12101C),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF2A2740))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide:
                          const BorderSide(color: _violeta, width: 2)),
                ),
              ),
            ),
          ),
          if (_catalogo.generos.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                children: [
                  _Genero(
                      rotulo: 'Todos',
                      ativo: _catalogo.genero.isEmpty,
                      onSelecionar: () => _filtrar('')),
                  for (final item in _catalogo.generos.entries)
                    _Genero(
                        rotulo: item.value,
                        ativo: item.key == _catalogo.genero,
                        onSelecionar: () => _filtrar(item.key)),
                ],
              ),
            ),
          ],
        ]),
      );

  Widget _corpo(BuildContext context) {
    if (_catalogo.erro != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ErroCatalogoPainel(
              mensagem: _catalogo.erro!,
              diagnostico: _catalogo.diagnostico,
              carregando: _catalogo.carregando,
              onTentarNovamente: _catalogo.tentarNovamente,
            ),
          ),
        ),
      );
    }
    if (_catalogo.jogos.isEmpty) {
      return Center(
        child: _catalogo.carregando
            ? const CircularProgressIndicator(color: _violeta)
            : const Text('Nenhum jogo encontrado. Tente outra busca.'),
      );
    }
    final jogos = _catalogo.jogos;
    return Focus(
      focusNode: _carrosselFocus,
      autofocus: true,
      child: PageView.builder(
        controller: _pagina,
        itemCount: jogos.length,
        // Snap de página com a inércia macia do Bouncing: o arrasto do mouse
        // desacelera em vez de parar seco no limite.
        physics:
            const PageScrollPhysics(parent: BouncingScrollPhysics()),
        onPageChanged: (indice) {
          if (indice == _indice) return;
          setState(() => _indice = indice);
          _som(SonsSistema.futuristicMove);
          if (indice >= jogos.length - 6) _carregarMais();
        },
        itemBuilder: (context, indice) {
          final distancia = (indice - _posicao).abs().clamp(0.0, 1.0);
          final destaque = 1 - distancia;
          return Transform.scale(
            // O cartão central fica maior; os vizinhos recuam sem sumir.
            scale: 0.82 + 0.18 * destaque,
            child: Opacity(
              opacity: 0.45 + 0.55 * destaque,
              child: DescobrirCard(
                jogo: jogos[indice],
                destaque: destaque,
                onAbrir: () => indice == _indice ? _abrir() : _irPara(indice),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rodape(BuildContext context) {
    final jogos = _catalogo.jogos;
    if (jogos.isEmpty) return const SizedBox(height: 16);
    final atual = jogos[_indice.clamp(0, jogos.length - 1)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
      child: Column(children: [
        Text(atual.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
        const SizedBox(height: 6),
        Text(
            '${_indice + 1} de ${jogos.length}'
            '${_catalogo.total.isEmpty ? '' : ' · ${_catalogo.total}'}',
            style: const TextStyle(color: Color(0xFF8E88A3), fontSize: 12)),
        const SizedBox(height: 10),
        if (_catalogo.carregando)
          const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                  minHeight: 2, color: _violeta))
        else
          const Text('← → navegar · A abrir · B voltar',
              style: TextStyle(color: Color(0xFF6B6681), fontSize: 11)),
      ]),
    );
  }
}

class _Genero extends StatelessWidget {
  const _Genero(
      {required this.rotulo, required this.ativo, required this.onSelecionar});
  final String rotulo;
  final bool ativo;
  final VoidCallback onSelecionar;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onSelecionar,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: ativo
                  ? const Color(0xFFB6A8FF)
                  : const Color(0xFF14121E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: ativo
                      ? const Color(0xFFB6A8FF)
                      : const Color(0xFF2A2740)),
            ),
            child: Text(rotulo,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: ativo ? FontWeight.w800 : FontWeight.w500,
                    color: ativo ? Colors.black : Colors.white70)),
          ),
        ),
      );
}
