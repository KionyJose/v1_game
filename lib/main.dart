// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

// import 'dart:io';


import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Tela/Principal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  // Solicitar permissão de armazenamento externo
  var status = await Permission.storage.request();  
  if (status.isGranted) {
    runApp(const MyApp());
  } else {
    // Se a permissão não for concedida, exiba uma mensagem ao usuário ou tome outra ação apropriada
    debugPrint('Permissão de armazenamento não concedida');
  }
  // runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'V1_Games',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Principal(title: 'V1_Games 007'),
    );
  }
}


