import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../System/app_storage.dart';

/// Por que o catálogo não carregou.
///
/// A tela mostrava uma frase só — "Verifique sua conexão" — para causas que
/// pedem ações opostas: provedor bloqueando o domínio, Cloudflare recusando o
/// IP, site fora do ar e mudança de layout. Sem separar isso não dá para
/// saber, pela máquina do cliente, o que aconteceu.
enum FalhaCatalogo {
  enderecoInvalido,
  dnsBloqueado,
  semRede,
  tlsBloqueado,
  tempoEsgotado,
  acessoRecusado,
  excessoDePedidos,
  bloqueioLegal,
  siteIndisponivel,
  respostaInesperada,
  respostaIlegivel,
  estruturaMudou,
  desconhecida,
}

/// Uma falha de catálogo já classificada, com texto para o cliente e detalhe
/// técnico para quem recebe o relato.
@immutable
class DiagnosticoCatalogo {
  final FalhaCatalogo falha;

  /// O que o cliente lê na tela: causa provável e o que ele pode fazer.
  final String mensagem;

  /// Linha técnica curta, do tipo que serve em um print de tela.
  final String detalhe;

  final Uri? endereco;
  final int? status;
  final DateTime quando;

  DiagnosticoCatalogo({
    required this.falha,
    required this.mensagem,
    required this.detalhe,
    this.endereco,
    this.status,
    DateTime? quando,
  }) : quando = quando ?? DateTime.now();

  /// Código curto para o cliente ditar por telefone ou mensagem.
  String get codigo => 'LOJA-${falha.name.toUpperCase()}';

  /// Bloco completo, para o botão de copiar e para o arquivo de log.
  String get relatorio => [
        'Código: $codigo',
        'Quando: ${quando.toIso8601String()}',
        if (endereco != null) 'Endereço: $endereco',
        if (status != null) 'HTTP: $status',
        'Detalhe: $detalhe',
      ].join('\n');

  /// Classifica o erro cru de rede ou de leitura.
  ///
  /// A ordem importa: `HandshakeException` é uma `SocketException`? Não, mas
  /// ambos aparecem embrulhados em `ClientException` pelo pacote http, então o
  /// embrulho é desfeito antes de olhar o tipo.
  factory DiagnosticoCatalogo.de(Object erro, {Uri? endereco, int? status}) {
    final alvo = _desembrulhar(erro);
    final texto = alvo.toString();

    if (alvo is TimeoutException) {
      return DiagnosticoCatalogo(
        falha: FalhaCatalogo.tempoEsgotado,
        mensagem: 'O site não respondeu a tempo. Isso costuma ser internet '
            'lenta ou o provedor segurando a conexão. Tente novamente; se '
            'repetir, teste em outra rede.',
        detalhe: 'Tempo esgotado: $texto',
        endereco: endereco,
      );
    }
    if (alvo is HandshakeException || alvo is TlsException) {
      return DiagnosticoCatalogo(
        falha: FalhaCatalogo.tlsBloqueado,
        mensagem: 'A conexão segura com o site foi recusada. Normalmente é '
            'antivírus com inspeção de HTTPS, proxy ou firewall da rede. '
            'Desative a inspeção de HTTPS do antivírus e tente de novo.',
        detalhe: 'Falha de TLS: $texto',
        endereco: endereco,
      );
    }
    if (alvo is SocketException) {
      // "Failed host lookup" é DNS: no Brasil costuma ser o provedor
      // bloqueando o domínio por ordem judicial, não falta de internet.
      final dns = alvo.osError?.errorCode == 11001 ||
          texto.contains('Failed host lookup') ||
          texto.contains('No address associated with hostname');
      if (dns) {
        // Chegar aqui significa que o contorno automático também não passou:
        // o caminho normal já teria trocado para o resolvedor DoH sozinho.
        // Por isso a mensagem não pede mais para trocar o DNS da máquina —
        // isso o aplicativo já faz por conta própria.
        return DiagnosticoCatalogo(
          falha: FalhaCatalogo.dnsBloqueado,
          mensagem: 'O endereço do site não foi encontrado, e a rota '
              'alternativa do aplicativo também não passou. A rede em uso '
              'bloqueia esse site de forma mais ampla. Teste pelo celular '
              'com 4G ou em outra rede.',
          detalhe: 'DNS não resolveu, inclusive pelo contorno: $texto',
          endereco: endereco,
        );
      }
      return DiagnosticoCatalogo(
        falha: FalhaCatalogo.semRede,
        mensagem: 'Não foi possível alcançar o site. Verifique se o '
            'computador está conectado e se firewall ou antivírus não estão '
            'bloqueando o aplicativo.',
        detalhe: 'Conexão recusada ou indisponível: $texto',
        endereco: endereco,
      );
    }
    if (alvo is FormatException) {
      return DiagnosticoCatalogo(
        falha: FalhaCatalogo.respostaIlegivel,
        mensagem: 'O site respondeu em um formato que o aplicativo não '
            'conseguiu ler. Pode ser uma página de bloqueio da rede no lugar '
            'do catálogo.',
        detalhe: 'Resposta ilegível: $texto',
        endereco: endereco,
        status: status,
      );
    }
    return DiagnosticoCatalogo(
      falha: FalhaCatalogo.desconhecida,
      mensagem: 'Não foi possível carregar o catálogo. Use o código abaixo '
          'ao relatar o problema.',
      detalhe: '${alvo.runtimeType}: $texto',
      endereco: endereco,
      status: status,
    );
  }

  /// Classifica uma resposta que chegou, mas não com HTTP 200.
  factory DiagnosticoCatalogo.doStatus(int status, {Uri? endereco}) {
    switch (status) {
      case 401:
      case 403:
        return DiagnosticoCatalogo(
          falha: FalhaCatalogo.acessoRecusado,
          mensagem: 'O site recusou o acesso deste computador (HTTP $status). '
              'Em geral é a proteção Cloudflare barrando o endereço IP: '
              'acontece com VPN, internet compartilhada e alguns provedores. '
              'Desligue a VPN ou teste em outra rede.',
          detalhe: 'Acesso recusado pelo site ou pela proteção Cloudflare.',
          endereco: endereco,
          status: status,
        );
      case 429:
        return DiagnosticoCatalogo(
          falha: FalhaCatalogo.excessoDePedidos,
          mensagem: 'O site pediu para esperar: muitos acessos em pouco tempo '
              '(HTTP 429). Aguarde alguns minutos e tente novamente.',
          detalhe: 'Limite de requisições do site atingido.',
          endereco: endereco,
          status: status,
        );
      case 451:
        return DiagnosticoCatalogo(
          falha: FalhaCatalogo.bloqueioLegal,
          mensagem: 'O conteúdo está indisponível nesta região por decisão '
              'legal (HTTP 451).',
          detalhe: 'Bloqueio legal informado pelo próprio site.',
          endereco: endereco,
          status: status,
        );
      default:
        if (status >= 500) {
          return DiagnosticoCatalogo(
            falha: FalhaCatalogo.siteIndisponivel,
            mensagem: 'O site está fora do ar no momento (HTTP $status). '
                'Não é problema do seu computador; tente mais tarde.',
            detalhe: 'Erro no servidor do site.',
            endereco: endereco,
            status: status,
          );
        }
        return DiagnosticoCatalogo(
          falha: FalhaCatalogo.respostaInesperada,
          mensagem: 'O site respondeu de forma inesperada (HTTP $status). '
              'Tente novamente em alguns minutos.',
          detalhe: 'Status HTTP fora do previsto.',
          endereco: endereco,
          status: status,
        );
    }
  }

  /// A resposta chegou inteira, mas não tem a cara do catálogo.
  factory DiagnosticoCatalogo.estrutura(String detalhe, {Uri? endereco}) =>
      DiagnosticoCatalogo(
        falha: FalhaCatalogo.estruturaMudou,
        mensagem: 'O site respondeu, mas o aplicativo não reconheceu o '
            'catálogo. O site provavelmente mudou de layout, ou a rede '
            'devolveu uma página de aviso no lugar dele. É preciso atualizar '
            'o aplicativo.',
        detalhe: detalhe,
        endereco: endereco,
      );

  factory DiagnosticoCatalogo.endereco(Uri? endereco) => DiagnosticoCatalogo(
        falha: FalhaCatalogo.enderecoInvalido,
        mensagem: 'Endereço de catálogo inválido.',
        detalhe: 'A tela pediu um endereço que não pertence à fonte.',
        endereco: endereco,
      );

  static Object _desembrulhar(Object erro) {
    // O pacote http embrulha SocketException/HandshakeException em
    // ClientException e perde o tipo; a mensagem preserva a causa.
    if (erro is http.ClientException) {
      final texto = erro.message;
      if (texto.contains('Failed host lookup')) {
        return SocketException(texto);
      }
      if (texto.contains('HandshakeException') ||
          texto.contains('CERTIFICATE')) {
        return HandshakeException(texto);
      }
      if (texto.contains('Connection') || texto.contains('SocketException')) {
        return SocketException(texto);
      }
    }
    return erro;
  }

  /// Arquivo que acumula as falhas na máquina do cliente.
  ///
  /// É o que permite pedir "me manda esse arquivo" em vez de depender da
  /// lembrança de quem viu a tela.
  static File get arquivoDeLog =>
      File('${AppStorage.root.path}${Platform.pathSeparator}loja-erros.log');

  /// Acrescenta o relatório ao log, sem nunca derrubar a tela por causa disso.
  Future<void> registrar() async {
    try {
      final arquivo = arquivoDeLog;
      await arquivo.parent.create(recursive: true);
      // Mantém o arquivo pequeno: um log que cresce sem limite é um log que
      // ninguém consegue enviar.
      if (await arquivo.exists() && await arquivo.length() > 256 * 1024) {
        await arquivo.writeAsString('');
      }
      await arquivo.writeAsString('$relatorio\n---\n',
          mode: FileMode.append, flush: true);
    } catch (error) {
      debugPrint('Não foi possível registrar o erro da loja: $error');
    }
  }
}
