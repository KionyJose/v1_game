// ignore_for_file: file_names

import 'dart:ffi';
import 'package:ffi/ffi.dart';

final user32 = DynamicLibrary.open('user32.dll');

typedef MouseEventC = Void Function(Int32 dwFlags, Int32 dx, Int32 dy, Int32 dwData, Int32 dwExtraInfo);
typedef MouseEventDart = void Function(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
final MouseEventDart mouseClick = user32.lookupFunction<MouseEventC, MouseEventDart>('mouse_event');

typedef SetCursorPosC = Int32 Function(Int32 x, Int32 y);
typedef SetCursorPosDart = int Function(int x, int y);
final setCursorPos = user32.lookupFunction<SetCursorPosC, SetCursorPosDart>('SetCursorPos');

typedef GetCursorPosC = Int32 Function(Pointer<MouseCtrl> lpPoint);
typedef GetCursorPosDart = int Function(Pointer<MouseCtrl> lpPoint);
final getCursorPos = user32.lookupFunction<GetCursorPosC, GetCursorPosDart>('GetCursorPos');

final class MouseCtrl extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;


  static void moveCursor(int dx, int dy) {
    final point = calloc<MouseCtrl>();
    getCursorPos(point);
    final currentX = point.ref.x;
    final currentY = point.ref.y;

    setCursorPos(currentX + dx, currentY + -dy);
    calloc.free(point);
  }

  static void simularClique() {
    final point = calloc<MouseCtrl>();
    int x = point.ref.x;
    int y = point.ref.y;
    // Mover o cursor
    // mouse_event(0x0001, x, y, 0, 0);  // Movimento do mouse (MOUSEEVENTF_MOVE)
  
    // Clicar
    mouseClick(0x0002, x, y, 0, 0);  // Pressionar o botão esquerdo do mouse (MOUSEEVENTF_LEFTDOWN)
    mouseClick(0x0004, x, y, 0, 0);  // Liberar o botão esquerdo do mouse (MOUSEEVENTF_LEFTUP)
  }


  

  


}


