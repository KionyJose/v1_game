// ignore_for_file: file_names
import 'package:flutter/material.dart';

class MsgButton {
  mensagem(BuildContext context, String str) {
    return ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(str),duration: const Duration(seconds: 2),));
  }
}
