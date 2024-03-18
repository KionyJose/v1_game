// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:v1_game/Global.dart';

// class MyTextField extends HookWidget {
//   @override
//   Widget build(BuildContext context) {
//     final textEditingController = useTextEditingController();

//     useEffect(() {
//       return navigatorKey.currentState?.addEventListener((event) {
//         if (event is RawKeyDownEvent) {
//           print('Tecla pressionada: ${event.logicalKey}');
//         } else if (event is RawKeyUpEvent) {
//           print('Tecla liberada: ${event.logicalKey}');
//         }
//       }) as void Function();
//     }, const []);

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Detecção de Teclado em Toda a API'),
//       ),
//       body: Center(
//         child: TextField(
//           controller: textEditingController,
//           onChanged: (String value) {
//             // Este callback é chamado sempre que o texto no TextField muda
//             print('Texto do TextField: $value');
//           },
//           onSubmitted: (String value) {
//             // Este callback é chamado quando o usuário pressiona "Enter" no teclado
//             print('Texto submetido: $value');
//           },
//         ),
//       ),
//     );
//   }
// }