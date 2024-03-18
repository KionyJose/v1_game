// import 'dart:ffi';
// // import 'dart:io';
// import 'package:ffi/ffi.dart';

// typedef SHGetFileInfoC = IntPtr Function(
//   Pointer<Utf16> pszPath,
//   Uint32 dwFileAttributes,
//   Pointer<SHFILEINFO> psfi,
//   Uint32 cbSizeFileInfo,
//   Uint32 uFlags,
// );

// class SHFILEINFO extends Struct {
//   @Uint32()
//   external int hIcon;

//   @Int32()
//   external int iIcon;

//   @Uint32()
//   external int dwAttributes;

//   @Array(260)
//   external Array<Utf16> szDisplayName;

//   @Array(80)
//   external Array<Utf16> szTypeName;
// }

// class Shell32 {
//   static final DynamicLibrary shell32 = DynamicLibrary.open('Shell32.dll');
//   static final SHGetFileInfoC shGetFileInfo =
//       shell32.lookupFunction<SHGetFileInfoC, SHGetFileInfoC>('SHGetFileInfoW');
// }

// IconData getIconForFile(String filePath) {
//   final fileInfo = calloc<SHFILEINFO>();
//   final pszPath = filePath.toNativeUtf16();
//   final flags = 0x100; // SHGFI_ICON
//   final result = Shell32.shGetFileInfo(
//     pszPath,
//     0,
//     fileInfo,
//     sizeOf<SHFILEINFO>(),
//     flags,
//   );
//   calloc.free(pszPath);

//   if (result == 0) {
//     throw Exception('Erro ao obter informações do arquivo');
//   }

//   final hIcon = fileInfo.ref.hIcon;
//   final icon = IconData(hIcon, fontFamily: 'Shell32');
//   calloc.free(fileInfo);

//   return icon;
// }
