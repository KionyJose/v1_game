// ignore_for_file: file_names
import 'dart:ffi';
import 'package:ffi/ffi.dart';
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
    }catch(e){print(e.toString());}
  }

  static void teclaEnters(){
    final input = calloc<INPUT>();
    input.ref.type = INPUT_TYPE.INPUT_KEYBOARD;
    input.ref.ki.wVk = VIRTUAL_KEY.VK_RETURN; // Tecla Enter

    // Simular tecla como se fosse física
    input.ref.ki.dwExtraInfo = GetMessageExtraInfo(); 

    SendInput(1, input, sizeOf<INPUT>());

    input.ref.ki.dwFlags = KEYBD_EVENT_FLAGS.KEYEVENTF_KEYUP; // Soltar tecla
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
}