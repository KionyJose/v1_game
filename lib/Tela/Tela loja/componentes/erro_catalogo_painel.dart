import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../scraps/diagnostico_catalogo.dart';

/// O que a tela mostra quando o catálogo não carrega.
///
/// Antes era uma linha de texto e um botão. Na máquina do cliente isso não
/// dizia nada: a mesma frase aparecia para DNS bloqueado pelo provedor, 403
/// do Cloudflare, antivírus cortando HTTPS e mudança de layout do site. Aqui
/// cada causa tem a sua frase, um código curto para o cliente ditar e o
/// detalhe técnico pronto para copiar.
class ErroCatalogoPainel extends StatelessWidget {
  const ErroCatalogoPainel({
    super.key,
    required this.mensagem,
    required this.diagnostico,
    required this.carregando,
    required this.onTentarNovamente,
  });

  final String mensagem;
  final DiagnosticoCatalogo? diagnostico;
  final bool carregando;
  final VoidCallback? onTentarNovamente;

  Future<void> _copiar(BuildContext context) async {
    final causa = diagnostico;
    if (causa == null) return;
    await Clipboard.setData(ClipboardData(text: causa.relatorio));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Detalhes copiados. Envie para o suporte.')));
  }

  @override
  Widget build(BuildContext context) {
    final causa = diagnostico;
    return Card(
      color: const Color(0xFF1A1016),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF7A3B4C))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF9BB0)),
            const SizedBox(width: 12),
            Expanded(
                child: Text('O catálogo não carregou',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 12),
          // Semantics marca a região para o leitor de tela anunciar a troca.
          Semantics(liveRegion: true, child: Text(mensagem)),
          if (causa != null) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: [
              _Etiqueta(texto: causa.codigo),
              if (causa.status != null)
                _Etiqueta(texto: 'HTTP ${causa.status}'),
            ]),
            const SizedBox(height: 12),
            Theme(
              // O ExpansionTile desenha divisórias claras sobre o fundo escuro.
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Detalhes técnicos'),
                subtitle: const Text(
                    'Mostre isto ao suporte se o erro continuar.'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0D0A0C),
                        borderRadius: BorderRadius.circular(10)),
                    child: SelectableText(causa.relatorio,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12)),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Também gravado em ${DiagnosticoCatalogo.arquivoDeLog.path}',
                        style: const TextStyle(
                            color: Color(0xFF9A93A5), fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 8, children: [
            FilledButton.icon(
                autofocus: true,
                onPressed: carregando ? null : onTentarNovamente,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente')),
            if (causa != null)
              TextButton.icon(
                  onPressed: () => _copiar(context),
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('Copiar detalhes')),
          ]),
        ]),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xFF2A1B22),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF7A3B4C))),
        child: Text(texto,
            style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      );
}
