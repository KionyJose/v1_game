// ignore_for_file: file_names, depend_on_referenced_packages, constant_identifier_names

import 'dart:ffi';
import 'dart:async'; // Para usar o Future.delayed
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

final user32 = DynamicLibrary.open('user32.dll');

typedef ShowWindowC = Int32 Function(IntPtr hWnd, Uint32 nCmdShow);
typedef ShowWindowDart = int Function(int hWnd, int nCmdShow);

typedef FindWindowC = IntPtr Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);
typedef FindWindowDart = int Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);

typedef SetForegroundWindowC = Int32 Function(IntPtr hWnd);
typedef SetForegroundWindowDart = int Function(int hWnd);



//==============================================================================================
// Janela Visivel ==============================================================================
typedef IsWindowVisibleC = Int32 Function(IntPtr hWnd);
typedef IsWindowVisibleDart = int Function(int hWnd);
//==============================================================================================
//  janela para o topo =========================================================================
  typedef BringWindowToTopC = Int32 Function(IntPtr hWnd);
  typedef BringWindowToTopDart = int Function(int hWnd);
//==============================================================================================
// TROCA NOME JANELA ===========================================================================
  typedef SetWindowTextC = Int32 Function(IntPtr hWnd, Pointer<Utf16> lpString);
  typedef SetWindowTextDart = int Function(int hWnd, Pointer<Utf16> lpString);
// =============================================================================================









class JanelaCtrl with ChangeNotifier, WindowListener{

  
  String nomeJanelaSistema = "v1_game"; 
  static const int SW_MINIMIZE = 6;
  static const int SW_RESTORE = 9;  
  static const int SW_SHOWNORMAL = 1;  
  static final hWnd = user32.lookupFunction<FindWindowC, FindWindowDart>('FindWindowW')(nullptr, "v1_game".toNativeUtf16());

  bool ativa = false;
  // deixar ativo depois
  bool telaPresa = false;
  
  
  
  attTela() => notifyListeners();
  JanelaCtrl({bool escuta = false}){    
    if(escuta)windowManager.addListener(this);
  }

  telaPresaReverse({bool usarEstado = false, bool estado = false}) {
    if(usarEstado){
      telaPresa = estado;
    }else{
      telaPresa = !telaPresa;
    }
    attTela();
  }
  
  @override
  void dispose() {
    debugPrint("SAIU PAGE JANELA");
    // ctrl.dispose();
    windowManager.removeListener(this);
    super.dispose();
  } 

  @override
  void onWindowEvent(String eventName) async {
    debugPrint('============================================================================ $eventName');    
  }
  
  @override void onWindowFocus() => ativa = true;
  @override void onWindowBlur() {
     ativa = false;
     if(telaPresa && !ativa) restoreWindow();
  }

  static janelaAtiva () async => await windowManager.isFocused();



  static void restoreWindow () async {
    // if(await windowManager.isVisible()) return;
    await windowManager.minimize();
    await windowManager.minimize();
    Future.delayed(const Duration(milliseconds: 200));
    await windowManager.maximize();
    await windowManager.focus();
    await windowManager.maximize();
    // windowManager.show();    
    debugPrint("Restart Tela Tras pra frente =======================================");
  }

  static void restoreWindow2(String windowName) {

    // final findWindow = user32.lookupFunction<FindWindowC, FindWindowDart>('FindWindowW');
    final showWindow = user32.lookupFunction<ShowWindowC, ShowWindowDart>('ShowWindow');
    final setForegroundWindow = user32.lookupFunction<SetForegroundWindowC, SetForegroundWindowDart>('SetForegroundWindow');

    final lpWindowName = windowName.toNativeUtf16();
    // final hWnd = findWindow(nullptr, lpWindowName);

    if (hWnd != 0) {
      // Minimiza a janela
      showWindow(hWnd, SW_MINIMIZE);

      // Aguarda e então restaura a janela e a traz para a frente
      Future.delayed(const Duration(milliseconds: 100), () {
        setForegroundWindow(hWnd);    // Traz a janela para frente
        showWindow(hWnd, SW_SHOWNORMAL); // Restaura a janela
        showWindow(hWnd, SW_RESTORE); // Restaura a janela
      });
    } else {
      debugPrint("Janela não encontrada.");
    }

    calloc.free(lpWindowName);
  }
  static verificaVisibilidade(){

    final isWindowVisible = user32.lookupFunction<IsWindowVisibleC, IsWindowVisibleDart>('IsWindowVisible');
    final visible = isWindowVisible(hWnd) != 0;
    debugPrint(visible ? 'A janela está visível' : 'A janela está oculta');
    return visible;
  }

  static janelaMoveTopo(){    
    final bringWindowToTop = user32.lookupFunction<BringWindowToTopC, BringWindowToTopDart>('BringWindowToTop');
    bringWindowToTop(hWnd);    
  }

  static trocaNomeJanela(){
    final setWindowText = user32.lookupFunction<SetWindowTextC, SetWindowTextDart>('SetWindowTextW');
    final newTitle = 'V1 Launch'.toNativeUtf16();
    setWindowText(hWnd, newTitle);
    calloc.free(newTitle);  
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



