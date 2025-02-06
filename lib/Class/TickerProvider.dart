// ignore_for_file: file_names

import 'package:flutter/scheduler.dart';

class MyTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}