// ignore_for_file: file_names, depend_on_referenced_packages, constant_identifier_names

import 'dart:ffi';
import 'dart:async'; // Para usar o Future.delayed
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

typedef ShowWindowC = Int32 Function(IntPtr hWnd, Uint32 nCmdShow);
typedef ShowWindowDart = int Function(int hWnd, int nCmdShow);

typedef FindWindowC = IntPtr Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);
typedef FindWindowDart = int Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);

typedef SetForegroundWindowC = Int32 Function(IntPtr hWnd);
typedef SetForegroundWindowDart = int Function(int hWnd);

class JanelaCtrl {
  static const int SW_MINIMIZE = 6;
  static const int SW_RESTORE = 9;

  static void restoreWindow(String windowName) {
    final user32 = DynamicLibrary.open('user32.dll');

    final findWindow = user32.lookupFunction<FindWindowC, FindWindowDart>('FindWindowW');
    final showWindow = user32.lookupFunction<ShowWindowC, ShowWindowDart>('ShowWindow');
    final setForegroundWindow = user32.lookupFunction<SetForegroundWindowC, SetForegroundWindowDart>('SetForegroundWindow');

    final lpWindowName = windowName.toNativeUtf16();
    final hWnd = findWindow(nullptr, lpWindowName);

    if (hWnd != 0) {
      // Minimiza a janela
      showWindow(hWnd, SW_MINIMIZE);

      // Aguarda 1 segundo e então restaura a janela e a traz para a frente
      Future.delayed(const Duration(milliseconds: 100), () {
        showWindow(hWnd, SW_RESTORE); // Restaura a janela
        setForegroundWindow(hWnd);    // Traz a janela para frente
      });
    } else {
      debugPrint("Janela não encontrada.");
    }

    calloc.free(lpWindowName);
  }
}





















// // ignore_for_file: file_names, depend_on_referenced_packages, constant_identifier_names

// import 'dart:ffi';
// import 'package:ffi/ffi.dart';
// import 'package:flutter/material.dart';

// typedef ShowWindowC = Int32 Function(IntPtr hWnd, Uint32 nCmdShow);
// typedef ShowWindowDart = int Function(int hWnd, int nCmdShow);

// typedef FindWindowC = IntPtr Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);
// typedef FindWindowDart = int Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);

// class JanelaCtrl {
//   static const int SW_RESTORE = 9;

//   static void restoreWindow(String windowName) {
//     final user32 = DynamicLibrary.open('user32.dll');

//     final findWindow = user32.lookupFunction<FindWindowC, FindWindowDart>('FindWindowW');
//     final showWindow = user32.lookupFunction<ShowWindowC, ShowWindowDart>('ShowWindow');

//     final lpWindowName = windowName.toNativeUtf16();
//     final hWnd = findWindow(nullptr, lpWindowName);

//     if (hWnd != 0) {
//       showWindow(hWnd, SW_RESTORE);
//     } else {
//       debugPrint("Janela não encontrada.");
//     }

//     calloc.free(lpWindowName);
//   }
// }

//kiony



