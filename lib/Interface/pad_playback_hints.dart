import 'dart:async';
import 'package:flutter/material.dart';

class PadPlaybackHints extends StatefulWidget {
  const PadPlaybackHints({super.key, required this.text});
  final String text;
  @override
  State<PadPlaybackHints> createState() => PadPlaybackHintsState();
}

class PadPlaybackHintsState extends State<PadPlaybackHints> {
  Timer? _idle;
  bool _visible = true;
  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  void show() {
    if (!mounted) return;
    if (!_visible) setState(() => _visible = true);
    _scheduleHide();
  }

  void _scheduleHide() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _idle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(widget.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12))))));
}
