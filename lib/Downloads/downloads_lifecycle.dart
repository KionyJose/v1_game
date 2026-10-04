import 'package:flutter/material.dart';
import 'dart:ui' show AppExitResponse;
import 'downloads_controller.dart';

class DownloadsLifecycle extends StatefulWidget {
  final Widget child;
  const DownloadsLifecycle({super.key, required this.child});
  @override
  State<DownloadsLifecycle> createState() => _DownloadsLifecycleState();
}

class _DownloadsLifecycleState extends State<DownloadsLifecycle> {
  late final AppLifecycleListener _listener;
  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onExitRequested: () async {
      await DownloadsController.instance.shutdown();
      return AppExitResponse.exit;
    });
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
