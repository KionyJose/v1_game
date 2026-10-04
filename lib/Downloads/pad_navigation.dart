import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

enum PadCommand { up, down, left, right, select, back }

/// Leitura XInput local à tela: D-pad, analógico esquerdo, A e B.
/// Sem injetar teclas no Windows ou alterar o cursor do sistema.
class PadNavigation {
  final void Function(PadCommand) onCommand;
  Timer? _timer;
  final _state = calloc<XINPUT_STATE>();
  Set<PadCommand> _last = {};
  DateTime _repeatAt = DateTime.now();
  PadNavigation(this.onCommand);
  void start() {
    if (!Platform.isWindows) return;
    _timer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      for (var index = 0; index < 4; index++) {
        if (XInputGetState(index, _state) != 0) continue;
        final gamepad = _state.ref.Gamepad;
        final buttons = gamepad.wButtons;
        final pressed = <PadCommand>{
          if ((buttons & 1) != 0 || gamepad.sThumbLY > 18000) PadCommand.up,
          if ((buttons & 2) != 0 || gamepad.sThumbLY < -18000) PadCommand.down,
          if ((buttons & 4) != 0 || gamepad.sThumbLX < -18000) PadCommand.left,
          if ((buttons & 8) != 0 || gamepad.sThumbLX > 18000) PadCommand.right,
          if ((buttons & 0x1000) != 0) PadCommand.select,
          if ((buttons & 0x2000) != 0) PadCommand.back,
        };
        final now = DateTime.now();
        for (final command in pressed) {
          if (!_last.contains(command)) {
            onCommand(command);
            _repeatAt = now.add(const Duration(milliseconds: 400));
          } else if (command != PadCommand.select &&
              command != PadCommand.back &&
              now.isAfter(_repeatAt)) {
            onCommand(command);
            _repeatAt = now.add(const Duration(milliseconds: 150));
          }
        }
        _last = pressed;
        return;
      }
      _last = {};
    });
  }

  void dispose() {
    _timer?.cancel();
    calloc.free(_state);
  }
}
