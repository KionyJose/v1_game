// ignore_for_file: file_names, unused_local_variable

import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:v1_game/Class/TecladoCtrl.dart';

class NavWebCtrl{
  static Future<void> openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    Timer(const Duration(milliseconds: 800), () {
      TecladoCtrl.teclaF11();
    });
  }

  static Future<void> openSite(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}