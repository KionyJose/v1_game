// ignore_for_file: file_names, unnecessary_string_escapes
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:v1_game/Bando%20de%20Dados/db.dart';
import 'package:v1_game/Global.dart';
import 'package:win32/win32.dart';

// Carrega a biblioteca nativa
// final DynamicLibrary nativeLib = DynamicLibrary.open('send_key.dll');
// final DynamicLibrary nativeLib = DynamicLibrary.open('path/to/send_key.dll');
final DynamicLibrary nativeLib = DynamicLibrary.open('C:/caminho/para/send_key.dll');
// Define a assinatura da função C
typedef SendEnterKeyC = Void Function();
typedef SendEnterKeyDart = void Function();

class TecladoCtrl{



  static teclaEnter(){
    try{
    // Obtém a função da biblioteca
    final sendEnterKey = nativeLib.lookupFunction<SendEnterKeyC, SendEnterKeyDart>('sendEnterKey');
    // Chama a função para enviar a tecla "Enter"
    sendEnterKey();
    }catch(e){debugPrint(e.toString());}
  }

  static void teclaEnters(){
    final input = calloc<INPUT>();
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = VIRTUAL_KEY.VK_RETURN; // Código da tecla ENTER

    // Pressionar tecla
    SendInput(1, input, sizeOf<INPUT>());

    // Soltar tecla
    input.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(1, input, sizeOf<INPUT>());

    calloc.free(input);
  }
  

  static void teclaEspaco(){
    final input = calloc<INPUT>();
    input.  ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = VIRTUAL_KEY.VK_SPACE; // Código da tecla espaço
  
    // Pressionar tecla
    SendInput(1, input, sizeOf<INPUT>());
  
    // Soltar tecla
    input.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(1, input, sizeOf<INPUT>());
  
    calloc.free(input);
  }  
  static void teclaF11(){
    final input = calloc<INPUT>();
    input.    ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = VIRTUAL_KEY.VK_F11; // Código da tecla espaço
  
    // Pressionar tecla
    SendInput(1, input, sizeOf<INPUT>());
  
    // Soltar tecla
    input.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(1, input, sizeOf<INPUT>());
  
    calloc.free(input);
  }
  static void fecharAltF4() {
    final input = calloc<INPUT>(2);

    input[0].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[0].ki.wVk = VIRTUAL_KEY.VK_MENU;

    input[1].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[1].ki.wVk = VIRTUAL_KEY.VK_F4;

    SendInput(2, input, sizeOf<INPUT>());

    input[0].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    input[1].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(2, input, sizeOf<INPUT>());

    calloc.free(input);
  }

  static void teclaEsc() {
    final input = calloc<INPUT>();
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = VIRTUAL_KEY.VK_ESCAPE;

    SendInput(1, input, sizeOf<INPUT>());

    input.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(1, input, sizeOf<INPUT>());

    calloc.free(input);
  }

  static void teclaWindows() {
    final input = calloc<INPUT>();
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = VIRTUAL_KEY.VK_LWIN;

    SendInput(1, input, sizeOf<INPUT>());

    input.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(1, input, sizeOf<INPUT>());

    calloc.free(input);
  }

  static void holdShift() {
    final input = calloc<INPUT>();
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = VIRTUAL_KEY.VK_SHIFT;

    SendInput(1, input, sizeOf<INPUT>());
    calloc.free(input);
  } 
  static void soltaShift(){
    final input = calloc<INPUT>();
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = VIRTUAL_KEY.VK_SHIFT;
    input.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP; //=========================================================//============================================================//============================================================//==========================================================================================================================

    SendInput(1, input, sizeOf<INPUT>());
    calloc.free(input);
  }
  static void pressAltTab() {
    final input = calloc<INPUT>(2);

    input[0].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[0].ki.wVk = VIRTUAL_KEY.VK_MENU; // Alt

    input[1].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[1].ki.wVk = VIRTUAL_KEY.VK_TAB; // Tab

    SendInput(2, input, sizeOf<INPUT>());

    input[1].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    input[0].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(2, input, sizeOf<INPUT>());

    calloc.free(input);
  }

  static void pressWinTab() {
    final input = calloc<INPUT>(2);

    input[0].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[0].ki.wVk = VIRTUAL_KEY.VK_LWIN; // Windows

    input[1].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[1].ki.wVk = VIRTUAL_KEY.VK_TAB; // Tab

    SendInput(2, input, sizeOf<INPUT>());

    input[1].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    input[0].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(2, input, sizeOf<INPUT>());

    calloc.free(input);
  }
  // Função para simular Ctrl + Tab (próxima aba)
  static void nextPage() {
    final input = calloc<INPUT>(2);

    input[0].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[0].ki.wVk = VIRTUAL_KEY.VK_LCONTROL; // Ctrl

    input[1].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[1].ki.wVk = VIRTUAL_KEY.VK_NEXT; // pg dn

    SendInput(2, input, sizeOf<INPUT>());

    input[1].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    input[0].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(2, input, sizeOf<INPUT>());

    calloc.free(input);
  }

  // Função para simular Ctrl + Shift + Tab (aba anterior)
  static void previusPage() {
    final input = calloc<INPUT>(2);

    input[0].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[0].ki.wVk = VIRTUAL_KEY.VK_LCONTROL; // Windows

    input[1].type = INPUT_TYPE.INPUT_KEYBOARD;
    input[1].ki.wVk = VIRTUAL_KEY.VK_PRIOR; // Tab

    SendInput(2, input, sizeOf<INPUT>());

    input[1].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    input[0].ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP;
    SendInput(2, input, sizeOf<INPUT>());

    calloc.free(input);
  }

  static abrirTecladoVirtual() async {
    DB db = DB();
    final local = ('$localPai\\teclado_virtual.lnk');
    // const local = ('C:\\Users\\kiony\\OneDrive\\Área de Trabalho\\teclado_virtual.exe - Atalho.lnk');
    await db.openFile(local);
  }

}