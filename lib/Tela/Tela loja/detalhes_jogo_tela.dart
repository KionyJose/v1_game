import '../../Interface/launcher_header.dart';
import 'package:flutter/material.dart';
import '../../Interface/launcher_pad_scope.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../../Downloads/downloads_controller.dart';
import 'downloads/edge_torrent_downloader.dart';
import 'downloads/torrent_download.dart';
import 'componentes/jogo_midia.dart';
import 'componentes/game_identity.dart';
import 'componentes/galeria_jogo.dart';
import '../../Interface/pad_scroll_target.dart';
import '../../Interface/pad_directional_group.dart';
import 'scraps/catalogo_scraper.dart';
import 'scraps/gamestorrents_detalhes_scraper.dart';
import 'scraps/gamestorrents_download_scraper.dart';
import 'scraps/jogo_detalhes.dart';

class DetalhesJogoTela extends StatefulWidget {
  final JogoCatalogo jogo;
  final DetalhesScraper? scraper;
  final Widget Function(TrailerJogo)? trailerBuilder;
  final DownloadScraper? downloadScraper;
  final TorrentDownloader? downloader;
  final Future<void> Function(String, VersaoJogo, JogoCatalogo)?
      onTorrentRecebido;
  const DetalhesJogoTela(
      {super.key,
      required this.jogo,
      this.scraper,
      this.trailerBuilder,
      this.downloadScraper,
      this.downloader,
      this.onTorrentRecebido});
  @override
  State<DetalhesJogoTela> createState() => _DetalhesJogoTelaState();
}

class _DetalhesJogoTelaState extends State<DetalhesJogoTela> {
  late final DetalhesScraper _scraper;
  late final DownloadScraper _download;
  late final TorrentDownloader _downloader;
  late Future<JogoDetalhes> _detalhes;
  final _gallery = GlobalKey<GaleriaJogoState>();
  final _media = GlobalKey<JogoMidiaState>();
  final _buyFocus = FocusNode();
  final _versionFocus = FocusNode();
  final _cancelFocus = FocusNode();
  int _versao = 0;
  bool _consultando = false;
  bool _cancelamentoSolicitado = false;
  String? _erroDownload;
  String? _arquivoSalvo;
  ProgressoTorrent? _progresso;

  @override
  void initState() {
    super.initState();
    _scraper = widget.scraper ?? GamesTorrentsDetalhesScraper();
    _download = widget.downloadScraper ?? GamesTorrentsDownloadScraper();
    _downloader = widget.downloader ?? EdgeTorrentDownloader();
    _detalhes = _scraper.carregar(widget.jogo.pagina);
  }

  @override
  void dispose() {
    _buyFocus.dispose();
    _versionFocus.dispose();
    _cancelFocus.dispose();
    _scraper.dispose();
    _download.dispose();
    _downloader.cancelar();
    super.dispose();
  }

  void _atualizar() => setState(() {
        _versao = 0;
        _erroDownload = null;
        _detalhes = _scraper.carregar(widget.jogo.pagina);
      });

  Future<void> _comprar(VersaoJogo versao) async {
    setState(() {
      _consultando = true;
      _cancelamentoSolicitado = false;
      _erroDownload = null;
      _arquivoSalvo = null;
      _progresso = const ProgressoTorrent('Consultando a página de download…');
    });
    try {
      final etapa = await _download.consultar(versao.torrent);
      if (!mounted) return;
      if (_cancelamentoSolicitado) throw StateError('Download cancelado.');
      final arquivo = await _downloader.baixar(etapa, (progresso) {
        if (mounted) setState(() => _progresso = progresso);
      });
      if (mounted) setState(() => _arquivoSalvo = arquivo);
      if (widget.onTorrentRecebido != null) {
        await widget.onTorrentRecebido!(arquivo, versao, widget.jogo);
      } else {
        await DownloadsController.instance.registerPurchase(arquivo,
            sourceName: versao.fonte,
            edition: versao.titulo,
            pageUrl: widget.jogo.pagina.toString(),
            downloadUrl: versao.torrent.toString(),
            releaseInfo: versao.informacoes);
      }
      if (mounted) {
        setState(() {
          _arquivoSalvo = arquivo;
          _progresso = const ProgressoTorrent(
              'Arquivo .torrent baixado e confirmado.',
              fracao: 1);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erroDownload = e is ErroCatalogo
            ? e.mensagem
            : e is StateError
                ? e.message.toString()
                : 'Não foi possível consultar o download. Verifique sua conexão e tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _consultando = false;
          if (_erroDownload != null) _progresso = null;
        });
      }
    }
  }

  void _cancelarDownload() {
    _cancelamentoSolicitado = true;
    _downloader.cancelar();
    setState(() => _progresso = const ProgressoTorrent('Cancelando download…'));
  }

  Future<void> _abrirPasta() async {
    if (_arquivoSalvo == null) return;
    try {
      if (await launchUrl(Uri.directory(p.dirname(_arquivoSalvo!)),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {/* Exibe erro sem fechar a etapa. */}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a pasta.')));
  }

  @override
  Widget build(BuildContext context) => LauncherPadScope(
      onCommand: (command) => _gallery.currentState?.command(command) ?? false,
      child: Scaffold(
          backgroundColor: const Color(0xFF000000),
          appBar: LauncherHeader(title: Text(widget.jogo.nome)),
          body: FutureBuilder<JogoDetalhes>(
              future: _detalhes,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(snapshot.error is ErroCatalogo
                                ? (snapshot.error as ErroCatalogo).mensagem
                                : 'Não foi possível carregar os detalhes. Verifique sua conexão.'),
                            const SizedBox(height: 12),
                            FilledButton(
                                autofocus: true,
                                onPressed: _atualizar,
                                child: const Text('Tentar novamente'))
                          ])));
                }
                return _detailsLayout(context, snapshot.data!);
              })));

  bool _purchaseMove(TraversalDirection direction) {
    if (direction == TraversalDirection.down) {
      if (_versionFocus.hasFocus) {
        (_consultando ? _cancelFocus : _buyFocus).requestFocus();
      } else if (_gallery.currentState?.hasMedia ?? false) {
        _gallery.currentState?.focusSelected();
      } else {
        _media.currentState?.focusDescription();
      }
      return true;
    }
    if (direction == TraversalDirection.up) {
      if (_buyFocus.hasFocus && !_consultando) _versionFocus.requestFocus();
      return true;
    }
    return false;
  }

  Widget _detailsLayout(BuildContext context, JogoDetalhes jogo) {
    final gallery = PadScrollTarget(
        child: GaleriaJogo(
      key: _gallery,
      imagens: jogo.imagens,
      trailers: jogo.trailers,
      trailerBuilder: widget.trailerBuilder,
      autofocus: true,
      onVertical: (direction) {
        if (direction == TraversalDirection.up) {
          if (jogo.versoes.isNotEmpty) {
            (_consultando ? _cancelFocus : _buyFocus).requestFocus();
          }
        } else {
          _media.currentState?.focusDescription();
        }
        return true;
      },
    ));
    final purchase = PadDirectionalGroup(
        onMove: _purchaseMove, child: _purchasePanel(context, jogo));
    return SingleChildScrollView(
        child: Center(
            child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1600),
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth >= 1050) {
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 180,
                            child: GameIdentity(
                                jogo: jogo, fallbackImage: widget.jogo.imagem)),
                        const SizedBox(width: 24),
                        Expanded(child: gallery),
                        const SizedBox(width: 24),
                        SizedBox(width: 300, child: purchase),
                      ]);
                }
                if (constraints.maxWidth >= 750) {
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 260,
                            child: Column(children: [
                              GameIdentity(
                                  jogo: jogo,
                                  fallbackImage: widget.jogo.imagem,
                                  compact: true),
                              const SizedBox(height: 18),
                              purchase,
                            ])),
                        const SizedBox(width: 24),
                        Expanded(child: gallery),
                      ]);
                }
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GameIdentity(
                          jogo: jogo,
                          fallbackImage: widget.jogo.imagem,
                          compact: true),
                      const SizedBox(height: 18),
                      purchase,
                      const SizedBox(height: 24),
                      gallery,
                    ]);
              }),
              const SizedBox(height: 28),
              JogoMidia(
                  key: _media,
                  jogo: jogo,
                  onUp: () {
                    if (jogo.imagens.isNotEmpty || jogo.trailers.isNotEmpty) {
                      _gallery.currentState?.focusSelected();
                    } else if (jogo.versoes.isNotEmpty) {
                      (_consultando ? _cancelFocus : _buyFocus).requestFocus();
                    }
                  }),
            ],
          )),
    )));
  }

  Widget _purchasePanel(BuildContext context, JogoDetalhes jogo) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Versão do jogo',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (jogo.versoes.isEmpty)
              const Text('Nenhum botão de torrent encontrado para este jogo.')
            else ...[
              DropdownButtonFormField<int>(
                  focusNode: _versionFocus,
                  initialValue: _versao,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Selecionar versão'),
                  items: List.generate(
                      jogo.versoes.length,
                      (i) => DropdownMenuItem(
                          value: i,
                          child: Text(jogo.versoes[i].titulo,
                              maxLines: 1, overflow: TextOverflow.ellipsis))),
                  onChanged: _consultando
                      ? null
                      : (i) => setState(() {
                            _versao = i!;
                            _erroDownload = null;
                          })),
              const SizedBox(height: 14),
              Text(jogo.versoes[_versao].fonte),
              ...jogo.versoes[_versao].informacoes.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${e.key}: ${e.value}'))),
              const SizedBox(height: 20),
              FilledButton.icon(
                  autofocus: jogo.imagens.isEmpty && jogo.trailers.isEmpty,
                  focusNode: _buyFocus,
                  onPressed: _consultando
                      ? null
                      : () => _comprar(jogo.versoes[_versao]),
                  icon: _consultando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.download),
                  label: Text(_consultando ? 'Baixando torrent…' : 'Comprar')),
              const SizedBox(height: 10),
              const Text(
                  'Salva o .torrent em Downloads/games torrent compra. Não realiza pagamento.',
                  textAlign: TextAlign.center),
              if (_progresso != null) ...[
                const SizedBox(height: 12),
                Text(_progresso!.mensagem),
                if (_consultando) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: _progresso!.fracao),
                  TextButton(
                      focusNode: _cancelFocus,
                      onPressed: _cancelarDownload,
                      child: const Text('Cancelar download')),
                ],
              ],
              if (_arquivoSalvo != null) ...[
                const SizedBox(height: 8),
                SelectableText(_arquivoSalvo!),
                TextButton.icon(
                    onPressed: _abrirPasta,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Abrir pasta')),
              ],
              if (_erroDownload != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_erroDownload!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
            ],
          ])));
}
