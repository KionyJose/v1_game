
// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:v1_game/Modelos/ConfigSistema.dart';


bool notificacaoPop = false;
String msgNotificacao = "Notificado!";

// ACesssar na pasta debug
// C:\_Flutter\Game Interfacie\v1_game\build\windows\x64\runner\Debug\data\flutter_assets\assets
String localPai = "";
String localPath = "";
String assetsPath = "data\\flutter_assets\\assets";
//\\data\\flutter_assets\\assets\\";
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

ConfigSistema configSistema = ConfigSistema();
// int globalTamanhoWidth = MediaQuery().si