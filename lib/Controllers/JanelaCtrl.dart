// ignore_for_file: file_names, depend_on_referenced_packages, constant_identifier_names

import 'dart:ffi';
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

typedef GetForegroundWindowC = IntPtr Function();
typedef GetForegroundWindowDart = int Function();

typedef GetAncestorC = IntPtr Function(IntPtr hWnd, Uint32 gaFlags);
typedef GetAncestorDart = int Function(int hWnd, int gaFlags);



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
  static const String _nomeJanelaSistema = "v1_game";
  static const String _classeJanelaFlutter = "FLUTTER_RUNNER_WIN32_WINDOW";
  static const int GA_ROOT = 2;
  static const int SW_MINIMIZE = 6;
  static const int SW_RESTORE = 9;  
  static const int SW_SHOWNORMAL = 1;  

  bool ativa = false;
  bool _fechando = false;
  // deixar ativo depois
  bool telaPresa = true;
  
  
  
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

  @override
  void onWindowClose() async {
    if (_fechando) return;
    debugPrint('[FECHAR_APP] X da janela recebido pelo Flutter.');
    _fechando = true;
    await windowManager.destroy();
  }

  static Future<void> fecharAppForcado({String origem = 'desconhecida'}) async {
    debugPrint('[FECHAR_APP] Fechando janela solicitado por: $origem');
    await windowManager.destroy();
  }
  
  @override void onWindowFocus() => ativa = true;
  @override void onWindowBlur() {
     if (_fechando) {
       debugPrint('[FECHAR_APP] Blur ignorado porque o app esta fechando.');
       return;
     }
     ativa = false;
     if(telaPresa && !ativa) restoreWindow();
  }

  static janelaAtiva () async => await windowManager.isFocused();

  static int _buscarJanelaPrincipal() {
    final findWindow = user32.lookupFunction<FindWindowC, FindWindowDart>('FindWindowW');
    final lpClassName = _classeJanelaFlutter.toNativeUtf16();
    final lpWindowName = _nomeJanelaSistema.toNativeUtf16();
    var hwnd = findWindow(lpClassName, lpWindowName);
    if (hwnd == 0) {
      hwnd = findWindow(lpClassName, nullptr);
    }
    if (hwnd == 0) {
      hwnd = findWindow(nullptr, lpWindowName);
    }
    calloc.free(lpClassName);
    calloc.free(lpWindowName);
    return hwnd;
  }

  static bool appNaFrente() {
    final hwnd = _buscarJanelaPrincipal();
    if (hwnd == 0) return false;

    final getForegroundWindow =
        user32.lookupFunction<GetForegroundWindowC, GetForegroundWindowDart>('GetForegroundWindow');
    final getAncestor = user32.lookupFunction<GetAncestorC, GetAncestorDart>('GetAncestor');
    final foregroundWindow = getForegroundWindow();
    final foregroundRoot = foregroundWindow == 0 ? 0 : getAncestor(foregroundWindow, GA_ROOT);
    return foregroundWindow == hwnd || foregroundRoot == hwnd;
  }

  static Future<bool> garantirFocoSeNaFrente() async {
    if (await windowManager.isFocused()) return true;
    if (!appNaFrente()) return false;

    final hwnd = _buscarJanelaPrincipal();
    if (hwnd != 0) {
      final setForegroundWindow =
          user32.lookupFunction<SetForegroundWindowC, SetForegroundWindowDart>('SetForegroundWindow');
      setForegroundWindow(hwnd);
    }

    await windowManager.focus();
    return await windowManager.isFocused() || appNaFrente();
  }



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
    final hWnd = _buscarJanelaPrincipal();

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
    final hWnd = _buscarJanelaPrincipal();
    final visible = isWindowVisible(hWnd) != 0;
    debugPrint(visible ? 'A janela está visível' : 'A janela está oculta');
    return visible;
  }

  static janelaMoveTopo(){    
    final bringWindowToTop = user32.lookupFunction<BringWindowToTopC, BringWindowToTopDart>('BringWindowToTop');
    final hWnd = _buscarJanelaPrincipal();
    bringWindowToTop(hWnd);    
  }

  static trocaNomeJanela(){
    final setWindowText = user32.lookupFunction<SetWindowTextC, SetWindowTextDart>('SetWindowTextW');
    final newTitle = 'V1 Launch'.toNativeUtf16();
    final hWnd = _buscarJanelaPrincipal();
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



