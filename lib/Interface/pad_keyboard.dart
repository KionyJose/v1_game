import 'package:flutter/material.dart';
import 'launcher_pad_scope.dart';

Future<String?> abrirTecladoPad(BuildContext context, {String texto = ''}) =>
    showDialog<String>(
        context: context, builder: (_) => PadKeyboard(texto: texto));

class PadKeyboard extends StatefulWidget {
  final String texto;
  const PadKeyboard({super.key, this.texto = ''});
  @override
  State<PadKeyboard> createState() => _PadKeyboardState();
}

class _PadKeyboardState extends State<PadKeyboard> {
  late final TextEditingController _text =
      TextEditingController(text: widget.texto)
        ..selection = TextSelection.collapsed(offset: widget.texto.length);
  bool _upper = false;
  void _insert(String value) {
    final selection = _text.selection;
    final start = selection.isValid ? selection.start : _text.text.length;
    final end = selection.isValid ? selection.end : start;
    _text.value = TextEditingValue(
        text: _text.text.replaceRange(start, end, value),
        selection: TextSelection.collapsed(offset: start + value.length));
  }

  void _erase() {
    final selection = _text.selection;
    if (selection.isValid && !selection.isCollapsed) {
      _insert('');
      return;
    }
    final end = selection.isValid ? selection.start : _text.text.length;
    if (end == 0) return;
    final before = _text.text.substring(0, end);
    final runes = before.runes.toList()..removeLast();
    final remaining = String.fromCharCodes(runes);
    _text.value = TextEditingValue(
        text: remaining + _text.text.substring(end),
        selection: TextSelection.collapsed(offset: remaining.length));
  }

  void _done() => Navigator.pop(context, _text.text);
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LauncherPadScope(
        menu: false,
        onCommand: (command) {
          if (command == 'START') {
            _done();
            return true;
          }
          if (command == '1') {
            _erase();
            return true;
          }
          if (command == '4') {
            _insert(' ');
            return true;
          }
          return false;
        },
        child: Dialog(
            backgroundColor: const Color(0xFF151515),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Teclado interno',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                          controller: _text,
                          onSubmitted: (_) => _done(),
                          decoration: const InputDecoration(
                              labelText: 'Buscar jogos',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                          builder: (_, constraints) => Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: '1234567890qwertyuiopasdfghjklçzxcvbnmáéíóúãõ.-'
                                  .split('')
                                  .asMap()
                                  .entries
                                  .map((entry) => SizedBox(
                                      width: (constraints.maxWidth - 54) / 10,
                                      height: 46,
                                      child: FilledButton.tonal(
                                          autofocus: entry.key == 0,
                                          style: FilledButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8))),
                                          onPressed: () => _insert(
                                              _upper ? entry.value.toUpperCase() : entry.value),
                                          child: Text(_upper ? entry.value.toUpperCase() : entry.value, style: const TextStyle(fontSize: 18)))))
                                  .toList())),
                      const SizedBox(height: 16),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        OutlinedButton(
                            onPressed: () => setState(() => _upper = !_upper),
                            child: const Text('Maiúsculas')),
                        OutlinedButton(
                            onPressed: () => _insert(' '),
                            child: const Text('Espaço')),
                        OutlinedButton(
                            onPressed: _erase, child: const Text('Apagar')),
                        OutlinedButton(
                            onPressed: _text.clear,
                            child: const Text('Limpar')),
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar')),
                        FilledButton(
                            onPressed: _done, child: const Text('Concluir')),
                      ]),
                      const SizedBox(height: 12),
                      const Text(
                          'A: digitar • X: apagar • Y: espaço • Start: concluir • B: cancelar',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFB9B5D2))),
                    ])))),
      );
}
