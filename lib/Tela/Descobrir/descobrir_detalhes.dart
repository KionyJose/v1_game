import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Controllers/SonsSistema.dart';
import '../../Interface/launcher_header.dart';
import '../../Interface/launcher_pad_scope.dart';
import '../Tela loja/componentes/erro_catalogo_painel.dart';
import '../Tela loja/scraps/catalogo_scraper.dart';
import '../Tela loja/scraps/diagnostico_catalogo.dart';
import '../Tela loja/scraps/jogo_detalhes.dart';

/// Ficha do jogo vinda do Descobrir.
///
/// Empilhada, na ordem em que o olho lê: nome e ação na mesma linha, a imagem
/// grande logo abaixo, as miniaturas sob ela e a descrição no pé. O botão fica
/// **acima** da imagem porque é para lá que o direcional sobe a partir das
/// miniaturas — antes ele estava ao lado, e chegar nele exigia atravessar a
/// galeria inteira.
class DescobrirDetalhes extends StatefulWidget {
  const DescobrirDetalhes({
    super.key,
    required this.jogo,
    required this.scraper,
    this.sons = true,
  });

  final JogoCatalogo jogo;
  final DetalhesScraper scraper;
  final bool sons;

  @override
  State<DescobrirDetalhes> createState() => _DescobrirDetalhesState();
}

/// Onde o Pad está dentro da ficha, de cima para baixo.
enum _Zona { acao, galeria, descricao }

/// Uma miniatura da faixa: captura do jogo ou trailer.
class _Midia {
  const _Midia({required this.miniatura, this.imagem, this.video});
  final Uri miniatura;

  /// Captura para mostrar grande; nulo quando é vídeo.
  final Uri? imagem;

  /// Endereço do trailer; nulo quando é captura.
  final Uri? video;

  bool get ehVideo => video != null;
}

class _DescobrirDetalhesState extends State<DescobrirDetalhes> {
  late Future<JogoDetalhes> _ficha;
  final _abrirFocus = FocusNode(debugLabel: 'abrir na loja');
  final _rolagemDescricao = ScrollController();
  final _rolagemMiniaturas = ScrollController();

  _Zona _zona = _Zona.galeria;
  int _midia = 0;

  static const _violeta = Color(0xFFB6A8FF);
  static const _larguraDaMiniatura = 132.0;

  @override
  void initState() {
    super.initState();
    _ficha = widget.scraper.carregar(widget.jogo.pagina);
  }

  @override
  void dispose() {
    _abrirFocus.dispose();
    _rolagemDescricao.dispose();
    _rolagemMiniaturas.dispose();
    widget.scraper.dispose();
    super.dispose();
  }

  void _recarregar() =>
      setState(() => _ficha = widget.scraper.carregar(widget.jogo.pagina));

  void _som(void Function() tocar) {
    if (widget.sons) tocar();
  }

  /// Capturas e trailers na mesma faixa, nessa ordem.
  List<_Midia> _midias(JogoDetalhes jogo) => [
        for (final imagem in jogo.imagens)
          _Midia(miniatura: imagem, imagem: imagem),
        for (final trailer in jogo.trailers)
          _Midia(miniatura: trailer.miniatura, video: trailer.url),
      ];

  /// A captura grande é a última selecionada; um trailer não troca a imagem.
  Uri? _imagemGrande(List<_Midia> midias) {
    if (midias.isEmpty) return null;
    for (var i = _midia.clamp(0, midias.length - 1); i >= 0; i--) {
      final atual = midias[i].imagem;
      if (atual != null) return atual;
    }
    for (final midia in midias) {
      if (midia.imagem != null) return midia.imagem;
    }
    return null;
  }

  Future<void> _abrirNoNavegador(Uri endereco) async {
    _som(SonsSistema.futuristicOpen);
    try {
      if (await launchUrl(endereco, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {/* Mostra o aviso sem derrubar a ficha. */}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o endereço.')));
  }

  void _irParaMidia(int destino, int total) {
    if (total == 0) return;
    final alvo = destino.clamp(0, total - 1);
    if (alvo == _midia && _zona == _Zona.galeria) return;
    setState(() {
      _midia = alvo;
      _zona = _Zona.galeria;
    });
    _som(SonsSistema.futuristicMove);
    _revelarMiniatura(alvo);
  }

  /// Mantém a miniatura escolhida dentro da faixa visível.
  void _revelarMiniatura(int indice) {
    if (!_rolagemMiniaturas.hasClients) return;
    final posicao = _rolagemMiniaturas.position;
    const passo = _larguraDaMiniatura + 8;
    final inicio = indice * passo;
    final fim = inicio + passo;
    final alvo = inicio < posicao.pixels
        ? inicio
        : fim > posicao.pixels + posicao.viewportDimension
            ? fim - posicao.viewportDimension
            : posicao.pixels;
    _rolagemMiniaturas.animateTo(alvo.clamp(0.0, posicao.maxScrollExtent),
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _irParaZona(_Zona zona) {
    if (_zona == zona) return;
    setState(() => _zona = zona);
    if (zona == _Zona.acao) _abrirFocus.requestFocus();
    _som(SonsSistema.futuristicMove);
  }

  bool _comando(String comando, JogoDetalhes? ficha) {
    if (ficha == null) return false;
    final midias = _midias(ficha);
    switch (_zona) {
      case _Zona.acao:
        if (comando == 'BAIXO') {
          _irParaZona(
              midias.isEmpty ? _Zona.descricao : _Zona.galeria);
          return true;
        }
        if (comando == '2') {
          _abrirNoNavegador(ficha.urlLoja ?? widget.jogo.pagina);
          return true;
        }
        return false;

      case _Zona.galeria:
        switch (comando) {
          case 'ESQUERDA':
            _irParaMidia(_midia - 1, midias.length);
            return true;
          case 'DIREITA':
            _irParaMidia(_midia + 1, midias.length);
            return true;
          case 'CIMA':
            // O botão está acima da imagem: é para lá que se sobe.
            _irParaZona(_Zona.acao);
            return true;
          case 'BAIXO':
            if (ficha.descricao.isNotEmpty) _irParaZona(_Zona.descricao);
            return true;
          case '2':
            final atual = midias.isEmpty ? null : midias[_midia];
            // Confirmar numa captura não tem para onde ir; num trailer, abre.
            if (atual != null && atual.ehVideo) {
              _abrirNoNavegador(atual.video!);
            }
            return true;
        }
        return false;

      case _Zona.descricao:
        switch (comando) {
          case 'CIMA':
            if (_rolagemDescricao.hasClients &&
                _rolagemDescricao.offset > 0) {
              _rolarDescricao(-120);
            } else {
              _irParaZona(midias.isEmpty ? _Zona.acao : _Zona.galeria);
            }
            return true;
          case 'BAIXO':
            _rolarDescricao(120);
            return true;
        }
        return false;
    }
  }

  void _rolarDescricao(double delta) {
    if (!_rolagemDescricao.hasClients) return;
    final posicao = _rolagemDescricao.position;
    _rolagemDescricao.animateTo(
        (posicao.pixels + delta).clamp(0.0, posicao.maxScrollExtent),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<JogoDetalhes>(
        future: _ficha,
        builder: (context, snapshot) => LauncherPadScope(
          revealInitialFocus: false,
          onCommand: (comando) => _comando(comando, snapshot.data),
          child: Scaffold(
            backgroundColor: const Color(0xFF07060C),
            appBar: LauncherHeader(title: Text(widget.jogo.nome)),
            body: SafeArea(child: _corpo(context, snapshot)),
          ),
        ),
      );

  Widget _corpo(BuildContext context, AsyncSnapshot<JogoDetalhes> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator(color: _violeta));
    }
    final erro = snapshot.error;
    if (erro != null || snapshot.data == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ErroCatalogoPainel(
              mensagem: erro is ErroCatalogo
                  ? erro.mensagem
                  : 'Não foi possível carregar a ficha deste jogo.',
              diagnostico: erro is ErroCatalogo
                  ? erro.diagnostico
                  : (erro == null
                      ? null
                      : DiagnosticoCatalogo.de(erro,
                          endereco: widget.jogo.pagina)),
              carregando: false,
              onTentarNovamente: _recarregar,
            ),
          ),
        ),
      );
    }
    return _ficha_(context, snapshot.data!);
  }

  Widget _ficha_(BuildContext context, JogoDetalhes jogo) {
    final midias = _midias(jogo);
    return Padding(
      // Margem curta: o conteúdo é que tem de ocupar a tela.
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _cabecalho(context, jogo),
        const SizedBox(height: 12),
        Expanded(flex: 5, child: _imagemGrandeWidget(midias)),
        if (midias.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(height: 78, child: _faixaDeMidias(midias)),
        ],
        if (jogo.descricao.isNotEmpty) ...[
          const SizedBox(height: 10),
          Expanded(flex: 2, child: _descricao(context, jogo)),
        ],
      ]),
    );
  }

  /// Nome à esquerda, ação à direita, na mesma linha.
  Widget _cabecalho(BuildContext context, JogoDetalhes jogo) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(jogo.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)),
                  if (jogo.preco.isNotEmpty || jogo.generos.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      if (jogo.preco.isNotEmpty) ...[
                        Text(jogo.preco,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _violeta)),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(jogo.generos.join('  ·  '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF8E88A3))),
                      ),
                    ]),
                  ],
                ]),
          ),
          const SizedBox(width: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: _zona == _Zona.acao
                  ? [
                      BoxShadow(
                          color: _violeta.withValues(alpha: .45),
                          blurRadius: 22,
                          spreadRadius: 1)
                    ]
                  : null,
            ),
            child: FilledButton.icon(
                focusNode: _abrirFocus,
                style: FilledButton.styleFrom(
                    backgroundColor: _violeta,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 16),
                    side: BorderSide(
                        color: _zona == _Zona.acao
                            ? Colors.white
                            : Colors.transparent,
                        width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: () =>
                    _abrirNoNavegador(jogo.urlLoja ?? widget.jogo.pagina),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Visitar site')),
          ),
        ],
      );

  Widget _imagemGrandeWidget(List<_Midia> midias) {
    final grande = _imagemGrande(midias);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color:
                _zona == _Zona.galeria ? _violeta : const Color(0xFF23203a),
            width: _zona == _Zona.galeria ? 2 : 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: grande == null
            ? const ColoredBox(
                color: Color(0xFF14121E),
                child: Center(
                    child: Text('Este jogo não tem capturas publicadas.',
                        style: TextStyle(color: Color(0xFF8E88A3)))),
              )
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: CachedNetworkImage(
                  key: ValueKey(grande),
                  imageUrl: grande.toString(),
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const ColoredBox(color: Color(0xFF14121E)),
                  errorWidget: (_, __, ___) =>
                      const ColoredBox(color: Color(0xFF14121E)),
                ),
              ),
      ),
    );
  }

  Widget _faixaDeMidias(List<_Midia> midias) => ListView.separated(
        controller: _rolagemMiniaturas,
        scrollDirection: Axis.horizontal,
        itemCount: midias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final midia = midias[i];
          final apontada = i == _midia && _zona == _Zona.galeria;
          return GestureDetector(
            onTap: () => midia.ehVideo && i == _midia
                ? _abrirNoNavegador(midia.video!)
                : _irParaMidia(i, midias.length),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _larguraDaMiniatura,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: apontada ? _violeta : const Color(0xFF2A2740),
                    width: apontada ? 2 : 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(fit: StackFit.expand, children: [
                  CachedNetworkImage(
                      imageUrl: midia.miniatura.toString(),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF14121E))),
                  if (midia.ehVideo)
                    const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0x66000000)),
                      child: Center(
                          child: Icon(Icons.play_circle_fill_rounded,
                              color: Colors.white, size: 30)),
                    ),
                ]),
              ),
            ),
          );
        },
      );

  Widget _descricao(BuildContext context, JogoDetalhes jogo) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0B14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: _zona == _Zona.descricao
                  ? _violeta
                  : const Color(0xFF23203a),
              width: _zona == _Zona.descricao ? 2 : 1),
        ),
        child: Scrollbar(
          controller: _rolagemDescricao,
          child: SingleChildScrollView(
            controller: _rolagemDescricao,
            child: Text(jogo.descricao,
                style: const TextStyle(height: 1.5, fontSize: 13)),
          ),
        ),
      );
}
