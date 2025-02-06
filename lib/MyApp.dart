// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Tela/PrincipalPage.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

import 'Controllers/Notificacao.dart';
import 'Widgets/NotificacaoPop.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      child: Consumer<Notificacao>(builder: (context, notf, child) => body(notf)),
    );
  }

  body(Notificacao notf) {
    debugPrint("Iniciado materialApp");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'V1_Games',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              const PrincipalPage(title: 'V1_Games 007'),
              if (notf.ativo)const Positioned(bottom: 20, right: 20, child: NotificacaoPop()),
              escutaPads(),
            ],
          ),
        ),
      ),
    );
  }

  escutaPads(){
    late int total;
    return Selector<Paad, List<Controller>>(
      selector: (context, paad) {
        total = paad.controlesAtivos.length;
        return paad.controlesAtivos; // Escuta apenas click
      },
      builder: (context, valorAtual, child) {
        // Aguardando o próximo frame para chamar o showDialog
        return statusPad(total);
      },
    );
  }

  // escutaNotfy(){
  //   return Selector<Notificacao, String>(
  //     selector: (context, paad) => paad.click, // Escuta apenas click
  //     builder: (context, valorAtual, child) {
  //       debugPrint("Click Paad: $valorAtual" );
  //       ctrl.escutaPad(valorAtual);
  //       return scaffold(ctrl);
  //     },
  //   );
  //   if (notf.ativo){
  //     return  const Positioned(bottom: 20, right: 20, child: NotificacaoPop());
  //   }
  //   return Container();
  // }

  statusPad(int paad){
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(paad.toString(),style: TextStyle(fontSize: 12,color: paad ==0 ? Colors.red: Colors.white)),
            const SizedBox(width: 5),
            Icon(Icons.sports_esports,color: paad == 0 ? Colors.red: Colors.white),
          ],
        ),
      ),
    );
  }
}
