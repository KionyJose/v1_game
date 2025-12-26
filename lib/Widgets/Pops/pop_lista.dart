import 'package:flutter/material.dart';

/// Mostra um dialog com uma lista de itens clicáveis
/// 
/// [context] - Contexto do Flutter para exibir o dialog
/// [titulo] - Título do dialog
/// [itens] - Lista de strings para exibir
/// [onItemSelecionado] - Callback executado quando um item é clicado
Future<void> mostrarPopLista({
  required BuildContext context,
  required String titulo,
  required List<String> itens,
  required Function(String) onItemSelecionado,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(titulo),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: itens.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum item disponível',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: itens.length,
                  itemBuilder: (context, index) {
                    final item = itens[index];
                    return ListTile(
                      title: Text(item),
                      onTap: () {
                        Navigator.of(context).pop();
                        onItemSelecionado(item);
                      },
                      hoverColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}

/// Mostra um dialog com uma lista de itens customizáveis
/// 
/// [context] - Contexto do Flutter para exibir o dialog
/// [titulo] - Título do dialog
/// [itens] - Lista de widgets para exibir
Future<void> mostrarPopListaCustomizada({
  required BuildContext context,
  required String titulo,
  required List<Widget> itens,
}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(titulo),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: itens.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum item disponível',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: itens,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}
