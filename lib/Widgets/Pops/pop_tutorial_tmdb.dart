// Passo a passo para conseguir a chave da API do TMDB.
//
// Abre por cima das Configurações, pelo botão "Como conseguir a chave".
// Existe porque a chave é a única coisa que o launcher não consegue resolver
// sozinho: ela depende de uma conta no site, e quem está no sofá com o
// controle na mão não tem como adivinhar onde ela fica.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Class/Paad.dart';
import '../../Controllers/MovimentoSistema.dart';
import '../../Controllers/NavWebCtrl.dart';
import '../../Controllers/SonsSistema.dart';

class PopTutorialTmdb {
  PopTutorialTmdb._();

  static const String site = 'https://www.themoviedb.org/settings/api';

  /// Os passos, na ordem em que aparecem no site.
  static const List<String> passos = [
    'Entre em themoviedb.org e crie sua conta (ou faça login).',
    'Clique no seu avatar, no canto superior direito, e escolha '
        '"Configurações".',
    'No menu da esquerda, clique em "API".',
    'Em "Solicitar uma chave de API", escolha a opção de uso pessoal '
        '("Developer").',
    'Aceite os termos e preencha o formulário: nome do aplicativo (pode ser '
        '"V1 Launcher"), tipo, endereço do site (pode ser qualquer um seu) e '
        'uma descrição curta.',
    'Pronto: a página mostra a "Chave da API (v3 auth)". Copie esse código.',
    'Volte aqui, abra o campo "Chave da API do TMDB" e cole o código.',
  ];

  /// Descarta o comando que abriu o tutorial antes de montar seus controles.
  static Future<void> abrir(BuildContext context) {
    context.read<Paad>().click = '';
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TutorialTmdb(),
    );
  }

  static Widget _passo(int numero, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF3B2BDB),
            ),
            child: Text(
              '$numero',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.35),
            ),
          ),
        ]),
      );

  /// Botão sem foco próprio: quem está escolhido é dito por [escolhido], que
  /// o direcional alterna — o mesmo desenho das Configurações.
  static Widget _botao(
    String texto,
    IconData icone,
    bool escolhido,
    VoidCallback aoTocar,
  ) =>
      GestureDetector(
        onTap: aoTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 46,
          decoration: BoxDecoration(
            color: escolhido
                ? const Color(0xFF3B2BDB).withValues(alpha: .75)
                : Colors.white10,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: escolhido ? Colors.white : Colors.white24,
              width: escolhido ? 2 : 1,
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icone, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              texto,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
      );
}

class _TutorialTmdb extends StatefulWidget {
  const _TutorialTmdb();

  @override
  State<_TutorialTmdb> createState() => _TutorialTmdbState();
}

class _TutorialTmdbState extends State<_TutorialTmdb> {
  final _foco = FocusNode();
  Paad? _pad;
  void Function()? _desanexar;
  Timer? _entrada;
  bool _aceitaConfirmar = false;
  bool _fechado = false;
  bool _abrindoSite = false;
  int _escolha = 0;

  @override
  void initState() {
    super.initState();
    // Também evita repetição física do botão usado para abrir o pop-up.
    _entrada = Timer(const Duration(milliseconds: 250), () {
      _aceitaConfirmar = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pad = context.read<Paad>();
    if (identical(_pad, pad)) return;
    _pad?.removeListener(_receberClick);
    _desanexar?.call();
    _pad = pad;
    pad.addListener(_receberClick);
    _desanexar = pad.interfaceRouter.attach(_agendarComando,
        acceptsCommand: () =>
            mounted &&
            !_fechado &&
            (ModalRoute.of(context)?.isCurrent ?? false));
  }

  void _receberClick() {
    if (!mounted || _fechado || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    final evento = _pad!.click;
    _pad!.click = '';
    _agendarComando(evento);
  }

  void _agendarComando(String evento) {
    if (evento.isEmpty || _fechado) return;
    _pad?.click = '';
    // O listener pode ser notificado durante um build do launcher.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          !_fechado &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        _comando(evento);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _comando(String evento) {
    switch (MovimentoSistema.normalizaEntrada(evento)) {
      case 'ESQUERDA':
      case 'DIREITA':
        setState(() => _escolha = _escolha == 0 ? 1 : 0);
        SonsSistema.click();
      case '2':
        if (!_aceitaConfirmar) return;
        _escolha == 0 ? _abrirSite() : _fechar();
      case '3':
        _fechar();
    }
  }

  void _fechar() {
    if (_fechado) return;
    _fechado = true;
    _pad?.click = '';
    Navigator.of(context).pop();
  }

  Future<void> _abrirSite() async {
    if (_fechado || _abrindoSite) return;
    _abrindoSite = true;
    final pad = _pad!;
    pad.click = '';
    try {
      // Destrava antes de abrir o navegador, para o launcher não roubar o
      // foco ao perder a janela. O mouse permanece livre para copiar a chave.
      pad.janelaCtrl.telaPresaReverse(usarEstado: true, estado: false);
      await pad.ativaMouse(usarEstado: true, estado: true);
      SonsSistema.pim();
      await NavWebCtrl.openSite(PopTutorialTmdb.site);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Não foi possível abrir o site do TMDB.'),
        ));
      }
    } finally {
      _abrindoSite = false;
    }
  }

  @override
  void dispose() {
    _fechado = true;
    _entrada?.cancel();
    _pad?.removeListener(_receberClick);
    _desanexar?.call();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyboardListener(
        focusNode: _foco,
        autofocus: true,
        onKeyEvent: (evento) {
          if (evento is KeyDownEvent) {
            _agendarComando(
                MovimentoSistema.convertKeyBoard(evento.logicalKey.keyLabel));
          }
        },
        child: _conteudo(context),
      );

  Widget _conteudo(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(8),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          color: Colors.black87,
          width: MediaQuery.of(context).size.width * .46,
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.vpn_key_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Como conseguir a chave do TMDB',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                const Text(
                  'É gratuita e leva uns cinco minutos. É ela que '
                  'traz capas, sinopses em português e trailers '
                  'para a aba Cinema.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 18),
                for (var i = 0; i < PopTutorialTmdb.passos.length; i++)
                  PopTutorialTmdb._passo(i + 1, PopTutorialTmdb.passos[i]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    PopTutorialTmdb.site,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: PopTutorialTmdb._botao(
                      'Acessar o site',
                      Icons.open_in_new_rounded,
                      _escolha == 0,
                      _abrirSite,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PopTutorialTmdb._botao(
                      'Fechar',
                      Icons.close_rounded,
                      _escolha == 1,
                      _fechar,
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
