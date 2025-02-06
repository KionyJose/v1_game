// ignore_for_file: file_names

import 'package:flutter/material.dart';

class LoadingIco extends StatelessWidget {
  const LoadingIco({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      height: MediaQuery.of(context).size.height * 0.12,
      width: MediaQuery.of(context).size.height * 0.12, 
      child: const CircularProgressIndicator(color: Colors.white70)
    ),
  );
  
}