import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One focus target; the launcher's settings dialog routes pad arrows to it.
class UiFpsOptions extends StatelessWidget {
  const UiFpsOptions(
      {super.key,
      required this.value,
      required this.focusNode,
      required this.onChanged});
  final int value;
  final FocusNode focusNode;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Focus(
            focusNode: focusNode,
            onKeyEvent: (_, event) {
              const options = [30, 60, 0];
              final key = event.logicalKey;
              final left = key == LogicalKeyboardKey.arrowLeft;
              if (!left &&
                  key != LogicalKeyboardKey.arrowRight &&
                  key != LogicalKeyboardKey.enter &&
                  key != LogicalKeyboardKey.numpadEnter) {
                return KeyEventResult.ignored;
              }
              if (event is KeyDownEvent ||
                  (event is KeyRepeatEvent &&
                      key != LogicalKeyboardKey.enter &&
                      key != LogicalKeyboardKey.numpadEnter)) {
                final index = options.indexOf(value);
                onChanged(options[(index + (left ? -1 : 1)) % options.length]);
              }
              return KeyEventResult.handled;
            },
            child: Builder(builder: (context) {
              final focused = Focus.of(context).hasFocus;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: focused ? Colors.white12 : Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: focused ? Colors.white : Colors.transparent,
                        width: 2)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FPS da UI',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: focused
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                      const SizedBox(height: 10),
                      Row(children: [
                        for (final option in const [
                          (30, '30'),
                          (60, '60'),
                          (0, 'Livre')
                        ])
                          Expanded(
                              child: Semantics(
                            button: true,
                            selected: value == option.$1,
                            label: option.$1 == 0
                                ? 'FPS Livre'
                                : '${option.$1} FPS',
                            child: GestureDetector(
                                onTap: () => onChanged(option.$1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                      color: value == option.$1
                                          ? const Color(0xB33B2BDB)
                                          : Colors.white10,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: value == option.$1
                                              ? const Color(0xFFB6A8FF)
                                              : Colors.transparent,
                                          width: 2)),
                                  child: Text(option.$2,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 15)),
                                )),
                          )),
                      ]),
                      const SizedBox(height: 8),
                      const Text(
                          'Livre acompanha a taxa de atualização do monitor.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
              );
            })),
      );
}
