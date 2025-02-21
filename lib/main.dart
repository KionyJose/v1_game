// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:v1_game/Bando%20de%20Dados/TESTES.dart';
import 'package:v1_game/MyApp.dart';
import 'package:window_manager/window_manager.dart';
import 'package:y_player/y_player.dart';
void main() async {

  WidgetsFlutterBinding.ensureInitialized();  
  YPlayerInitializer.ensureInitialized();
  
  await TESTES().testes();
  // Solicitar permissão de armazenamento externo
  var status = await Permission.storage.request();  
  if (status.isGranted) {
    runApp(const MyApp());
  } else {
    // Se a permissão não for concedida, exiba uma mensagem ao usuário ou tome outra ação apropriada
    debugPrint('Permissão de armazenamento não concedida');
  }
  windowFunctions();
  // fullScren();
}

// executaTeste()



Future windowFunctions() async {
  // Size size = await DesktopWindow.getWindowSize();
  
  await DesktopWindow.toggleFullScreen();
  await DesktopWindow.setFullScreen(true);
  // final screenSize = ui.window.physicalSize / ui.window.devicePixelRatio;
  // await DesktopWindow.setWindowSize(const Size(1920,1080));

  // await DesktopWindow.setMinWindowSize(const Size(400,400));
  // await DesktopWindow.setMaxWindowSize(const Size(800,800));

  await DesktopWindow.resetMaxWindowSize();
  // bool isFullScreen = await DesktopWindow.getFullScreen();
  await DesktopWindow.setFullScreen(true);
  // await DesktopWindow.setFullScreen(false);
}

fullScren() async {  
    
  //, 0, window.screen.frame.width, window.screen.frame.height));
  await windowManager.ensureInitialized();

  // Use it only after calling `hiddenWindowAtLaunch`
  windowManager.waitUntilReadyToShow().then((_) async {
  // Hide window title bar
  // await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  await windowManager.setFullScreen(true);
  await windowManager.center();
  await windowManager.show();
  await windowManager.setSkipTaskbar(false);
  });
}




//============================================================================================




//============================================================================================

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:gamepads/gamepads.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Gamepads Example',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   StreamSubscription<GamepadEvent>? _subscription;

//   List<GamepadController> _gamepads = [];
//   List<GamepadEvent> _lastEvents = [];
//   bool loading = false;

//   Future<void> _getValue() async {
//     setState(() => loading = true);
//     final response = await Gamepads.list();
//     setState(() {
//       _gamepads = response;
//       loading = false;
//     });
//   }

//   void _clear() {
//     setState(() => _lastEvents = []);
//   }

//   @override
//   void initState() {
//     super.initState();
//     _subscription = Gamepads.events.listen((GamepadEvent event) {

//       setState(() {
//         final newEvents = [ event,..._lastEvents,];
//         if (newEvents.length > 3) {
//           newEvents.removeRange(3, newEvents.length);
//         }
//         _lastEvents = newEvents;
//       });
//     });
//   }

//   @override
//   void dispose() {
//     _subscription?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Gamepads Example'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text('Last Events:'),
//             ..._lastEvents.map((e) => Text(e.toString())),
//             TextButton(
//               onPressed: _clear,
//               child: const Text('clear events'),
//             ),
//             const SizedBox(height: 16),
//             TextButton(
//               onPressed: _getValue,
//               child: const Text('listGamepads()'),
//             ),
//             const Text('Gamepads:'),
//             if (loading)
//               const CircularProgressIndicator()
//             else
//               ..._gamepads.map((e) => Text('${e.id} - ${e.name}'))
//           ],
//         ),
//       ),
//     );
//   }
// }