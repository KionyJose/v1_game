import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

const _pageReadWrite = 0x04;
const _fileMapAllAccess = 0xF001F;
const _invalidHandle = -1;
const _channelBytes = 256;

/// `Local\` em ASCII, com o terminador que o host nativo compara.
const _localPrefix = [0x4c, 0x6f, 0x63, 0x61, 0x6c, 0x5c, 0x00];

final _kernel32 = DynamicLibrary.open('kernel32.dll');

final _createFileMapping = _kernel32.lookupFunction<
    IntPtr Function(IntPtr, Pointer, Uint32, Uint32, Uint32, Pointer<Utf8>),
    int Function(
        int, Pointer, int, int, int, Pointer<Utf8>)>('CreateFileMappingA');

final _mapViewOfFile = _kernel32.lookupFunction<
    Pointer<Uint8> Function(IntPtr, Uint32, IntPtr, IntPtr, IntPtr),
    Pointer<Uint8> Function(int, int, int, int, int)>('MapViewOfFile');

final _unmapViewOfFile = _kernel32.lookupFunction<
    Int32 Function(Pointer<Uint8>),
    int Function(Pointer<Uint8>)>('UnmapViewOfFile');

final _closeHandle =
    _kernel32.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'CloseHandle');

/// `Init_MapFile_` é o canal em que os codecs CLS combinam o prefixo dos
/// objetos de IPC. Um codec pode deixar o canal marcado como `Global\`, que
/// exige privilégio de administrador, e um decodificador que não encerre mantém
/// esse canal vivo: a partir daí toda preparação da mesma sessão do Windows
/// falha com "Another installer is using the decoder initialization channel".
/// Prender o canal em `Local\` durante a extração encerra essa herança.
class DecoderChannel {
  final int _handle;
  final Pointer<Uint8> _view;
  DecoderChannel._(this._handle, this._view);

  static DecoderChannel? pin() {
    if (!Platform.isWindows) return null;
    final name = 'Init_MapFile_'.toNativeUtf8();
    try {
      final handle = _createFileMapping(
          _invalidHandle, nullptr, _pageReadWrite, 0, _channelBytes, name);
      if (handle == 0) return null;
      final view = _mapViewOfFile(handle, _fileMapAllAccess, 0, 0, 0);
      if (view == nullptr) {
        _closeHandle(handle);
        return null;
      }
      for (var i = 0; i < _localPrefix.length; i++) {
        view[i] = _localPrefix[i];
      }
      return DecoderChannel._(handle, view);
    } finally {
      calloc.free(name);
    }
  }

  void release() {
    _unmapViewOfFile(_view);
    _closeHandle(_handle);
  }
}
