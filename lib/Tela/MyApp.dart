// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Tela/Begin.dart';

import '../Controllers/Notificacao.dart';
import '../Downloads/downloads_lifecycle.dart';
import '../Controllers/launcher_window_controller.dart';
import '../System/startup_readiness.dart';
import '../System/startup_access_view.dart';
import '../Interface/text_viewer_dialog.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.readiness, this.onStorageRecovered});
  final StartupReadiness? readiness;
  final Future<void> Function()? onStorageRecovered;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StartupReadiness? _readiness;
  bool _checking = false;

  void _notifyReadiness() {
    if (_readiness?.storageReady != true || _readiness!.issues.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (!mounted || context == null) return;
      mostrarTextoAmpliado(context, titulo: 'Verificação inicial',
          texto: _readiness!.issues.join('\n\n'));
    });
  }

  Future<void> _retryAccess() async {
    setState(() => _checking = true);
    var report = await StartupReadiness.check();
    try {
      if (report.storageReady) await widget.onStorageRecovered?.call();
    } catch (error) {
      report = StartupReadiness(storageReady: false,
          issues: ['Não foi possível carregar as configurações: $error']);
    }
    if (!mounted) return;
    setState(() { _readiness = report; _checking = false; });
    _notifyReadiness();
  }
  @override
  void dispose() {
    LauncherWindowController.instance.dispose();
    super.dispose();
  }
  
   List<String> logs = [];
   String ultima = "";

  @override
  void initState() {
    super.initState();
    _readiness = widget.readiness;
    _notifyReadiness();
    
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
        ChangeNotifierProvider(create: (_) => JanelaCtrl(escuta: true)),
        ChangeNotifierProvider(create: (_) => Paad(escutar: true, janelaCtrl: _.read<JanelaCtrl>())),
        ChangeNotifierProvider(create: (_) => Notificacao()),
        //   ChangeNotifierProvider(create: (_) => Servidor()),
        //   ChangeNotifierProvider(create: (_) => User()),
      ],
      child: materialAppConfig(),
    );
  }

  materialAppConfig() {
    debugPrint("Iniciado materialApp");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      title: 'V1_Games',
      navigatorKey: navigatorKey,
      builder: (_, child) => DownloadsLifecycle(child: child ?? const SizedBox.shrink()),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: _readiness?.storageReady == false
          ? StartupAccessView(issues: _readiness!.issues,
              retry: _checking ? null : _retryAccess)
          : const Begin()
    );
  }

  
}
