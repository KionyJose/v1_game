// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Rotas/Rotas.dart';
import 'package:v1_game/Tela/Begin.dart';
import 'package:v1_game/Tela/PrincipalPage.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

import 'Controllers/Notificacao.dart';
import 'Widgets/NotificacaoPop.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  
   List<String> logs = [];
   String ultima = "";

  @override
  void initState() {
    super.initState();
    
    // Redireciona a função print para a função customizada
    // debugPrint = (String? message, {int? wrapWidth}) {
    //   // setState(() {
    //   attTelaLog(message!);
    //   // });
    // };
  }
  attTelaLog(String message){
    logs.insert(0,'debugPrint: $message');
    if(ultima != message){
      ultima = message;
      Timer(const Duration(microseconds: 20),(){setState(() {});});
    }
  }


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Paad(escutar: true)),
        ChangeNotifierProvider(create: (_) => Notificacao()),
        //   ChangeNotifierProvider(create: (_) => HomePageCtrl()),
        //   ChangeNotifierProvider(create: (_) => Servidor()),
        //   ChangeNotifierProvider(create: (_) => User()),
      ],
      child:  materialAppConfig(),
    );
  }

  materialAppConfig() {
    debugPrint("Iniciado materialApp");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateRoute: Rotas.geradorRotas,
      initialRoute: '/',
      title: 'V1_Games',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Begin()
    );
  }

  
}
