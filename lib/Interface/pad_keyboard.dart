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

  static const _ink = Color(0xFF11131D);
  static const _panel = Color(0xFF191B28);
  static const _violet = Color(0xFFB9A7FF);
  static const _water = Color(0xFFA9EEE4);
  static const _pearl = Color(0xFFF4F0FF);

  void _insert(String value) {
    final selection = _text.selection;
    final start = selection.isValid ? selection.start : _text.text.length;
    final end = selection.isValid ? selection.end : start;
    _text.value = TextEditingValue(
        text: _text.text.replaceRange(start, end, value),
        selection: TextSelection.collapsed(offset: start + value.length));
    setState(() {});
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
    setState(() {});
  }

  void _clear() {
    _text.clear();
    setState(() {});
  }

  /// O gatilho continua repetindo enquanto está pressionado, então sair tem de
  /// ser uma coisa só: sem isso, segurar RT fecharia também a tela de trás.
  bool _closed = false;

  void _done() {
    if (_closed) return;
    _closed = true;
    Navigator.pop(context, _text.text);
  }

  void _cancel() {
    if (_closed) return;
    _closed = true;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  ButtonStyle _keyStyle({bool accent = false}) => ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.zero),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return const Color(0xFF655594);
          }
          if (states.contains(WidgetState.pressed)) {
            return const Color(0xFF40375E);
          }
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF292638);
          }
          return accent ? const Color(0xFF272237) : _panel;
        }),
        foregroundColor: const WidgetStatePropertyAll(_pearl),
        side: WidgetStateProperty.resolveWith((states) => BorderSide(
            color: states.contains(WidgetState.focused)
                ? _water
                : accent
                    ? const Color(0x657B6BAC)
                    : const Color(0x32FFFFFF),
            width: states.contains(WidgetState.focused) ? 2 : 1)),
        textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      );

  Widget _letterKey(String value, double width, {bool autofocus = false}) =>
      SizedBox(
        width: width,
        height: 50,
        child: OutlinedButton(
            autofocus: autofocus,
            style: _keyStyle(),
            onPressed: () => _insert(_upper ? value.toUpperCase() : value),
            child: Text(_upper ? value.toUpperCase() : value)),
      );

  Widget _actionKey(
          {required String label,
          required IconData icon,
          required VoidCallback onPressed,
          bool selected = false}) =>
      OutlinedButton.icon(
        style: _keyStyle(accent: selected),
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      );

  Widget _commandHint(String key, String action) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: const Color(0x251F2030),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x267F78A0))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(key,
              style: const TextStyle(
                  color: _water,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5)),
          const SizedBox(width: 6),
          Text(action,
              style: const TextStyle(color: Color(0xFFC3C0D1), fontSize: 11)),
        ]),
      );

  Widget _keyboardKeys() => LayoutBuilder(builder: (_, constraints) {
        const spacing = 7.0;
        final columns = (constraints.maxWidth / 56).floor().clamp(4, 10);
        final keyWidth =
            ((constraints.maxWidth - (columns - 1) * spacing) / columns)
                .clamp(38.0, 66.0)
                .toDouble();
        const rows = [
          '1234567890',
          'qwertyuiop',
          'asdfghjklç',
          'zxcvbnm',
          'áéíóúãõ',
        ];
        var firstKey = true;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: spacing,
                      runSpacing: spacing,
                      children: row.split('').map((value) {
                        final autofocus = firstKey;
                        firstKey = false;
                        return _letterKey(value, keyWidth,
                            autofocus: autofocus);
                      }).toList()),
                ),
            ]);
      });

  @override
  Widget build(BuildContext context) => LauncherPadScope(
        menu: false,
        onCommand: (command) {
          // O gatilho direito chega como `RT-<força>`, já passado o deadzone
          // do próprio pacote; `RT`/`R2` cobrem os nomes usados nas outras
          // telas e no controle de PlayStation.
          if (command == 'START' ||
              command == 'RT' ||
              command == 'R2' ||
              command.startsWith('RT-') ||
              command.startsWith('R2-')) {
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xF21B1D2B), Color(0xF20C0F18)]),
                  border: Border.all(color: const Color(0x507E72AC)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x70000000),
                        blurRadius: 38,
                        offset: Offset(0, 18)),
                    BoxShadow(
                        color: Color(0x201CDBC7),
                        blurRadius: 34,
                        spreadRadius: -12)
                  ]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(colors: [
                                Color(0xFF66578E),
                                Color(0xFF324E60)
                              ]),
                              border:
                                  Border.all(color: const Color(0x70C9B9FF))),
                          child: const Icon(Icons.keyboard_rounded,
                              color: _pearl, size: 25),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Teclado interno',
                                    style: TextStyle(
                                        color: _pearl,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: .2)),
                                SizedBox(height: 3),
                                Text(
                                    'Digite pelo controle, toque ou teclado físico',
                                    style: TextStyle(
                                        color: Color(0xFFAAA8BC),
                                        fontSize: 12)),
                              ]),
                        ),
                        IconButton(
                            tooltip: 'Fechar',
                            onPressed: _cancel,
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFFC5C2D2),
                            style: IconButton.styleFrom(
                                backgroundColor: const Color(0x241F2030),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)))),
                      ]),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _text,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _done(),
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        style: const TextStyle(
                            color: _pearl,
                            fontSize: 17,
                            fontWeight: FontWeight.w500),
                        cursorColor: _water,
                        decoration: InputDecoration(
                          hintText: 'Digite aqui...',
                          hintStyle: const TextStyle(color: Color(0xFF79798B)),
                          prefixIcon:
                              const Icon(Icons.search_rounded, color: _violet),
                          suffixIcon: _text.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpar texto',
                                  onPressed: _clear,
                                  icon: const Icon(Icons.backspace_outlined),
                                  color: const Color(0xFFB6B1C8)),
                          filled: true,
                          fillColor: _ink,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                              borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                              borderSide:
                                  const BorderSide(color: Color(0x367B7593))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(17),
                              borderSide:
                                  const BorderSide(color: _water, width: 1.4)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        const Text('DIGITE SEU TEXTO',
                            style: TextStyle(
                                color: Color(0xFF9C98B2),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5)),
                        const Spacer(),
                        Text('${_text.text.length} caracteres',
                            style: const TextStyle(
                                color: Color(0xFF77768A), fontSize: 11)),
                      ]),
                      const SizedBox(height: 10),
                      _keyboardKeys(),
                      const SizedBox(height: 4),
                      LayoutBuilder(builder: (_, constraints) {
                        final compact = constraints.maxWidth < 540;
                        if (compact) {
                          return Column(children: [
                            Row(children: [
                              Expanded(
                                  child: _actionKey(
                                      label: 'Maiúsculas',
                                      icon: Icons.keyboard_capslock_rounded,
                                      selected: _upper,
                                      onPressed: () =>
                                          setState(() => _upper = !_upper))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _actionKey(
                                      label: 'Apagar',
                                      icon: Icons.backspace_outlined,
                                      onPressed: _erase)),
                            ]),
                            const SizedBox(height: 8),
                            SizedBox(
                                width: double.infinity,
                                child: _actionKey(
                                    label: 'Espaço',
                                    icon: Icons.space_bar_rounded,
                                    onPressed: () => _insert(' '))),
                          ]);
                        }
                        return Row(children: [
                          Expanded(
                              child: _actionKey(
                                  label: 'Maiúsculas',
                                  icon: Icons.keyboard_capslock_rounded,
                                  selected: _upper,
                                  onPressed: () =>
                                      setState(() => _upper = !_upper))),
                          const SizedBox(width: 8),
                          Expanded(
                              flex: 2,
                              child: _actionKey(
                                  label: 'Espaço',
                                  icon: Icons.space_bar_rounded,
                                  onPressed: () => _insert(' '))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _actionKey(
                                  label: 'Apagar',
                                  icon: Icons.backspace_outlined,
                                  onPressed: _erase)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _actionKey(
                                  label: 'Limpar',
                                  icon: Icons.delete_sweep_outlined,
                                  onPressed: _clear)),
                        ]);
                      }),
                      const SizedBox(height: 16),
                      Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 7,
                          runSpacing: 7,
                          children: [
                            _commandHint('A', 'digitar'),
                            _commandHint('X', 'apagar'),
                            _commandHint('Y', 'espaço'),
                            _commandHint('RT / Start', 'concluir'),
                            _commandHint('B', 'voltar'),
                          ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton(
                                style: _keyStyle(accent: true),
                                onPressed: _cancel,
                                child: const Text('Cancelar'))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: FilledButton.icon(
                                onPressed: _done,
                                icon: const Icon(Icons.check_rounded, size: 19),
                                label: const Text('Concluir'),
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                    backgroundColor: const Color(0xFF7463A8),
                                    foregroundColor: _pearl,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14))))),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
