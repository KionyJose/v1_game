import 'dart:async';
import 'package:flutter/widgets.dart';

/// A monotonic deadline avoids accumulating vsync rounding error at 120/165 Hz.
class UiFrameBudget {
  int _fps = 0;
  double _nextFrameUs = 0;
  int get fps => _fps;

  void setFps(int value) {
    _fps = value == 30 || value == 60 ? value : 0;
    _nextFrameUs = 0;
  }

  Duration delayAt(int nowUs) {
    if (_fps == 0) return Duration.zero;
    final delay = (_nextFrameUs - nowUs).ceil();
    return Duration(microseconds: delay > 0 ? delay : 0);
  }

  void frameBegan(int nowUs) {
    if (_fps == 0) return;
    final period = Duration.microsecondsPerSecond / _fps;
    // Native resize/video frames may arrive before our deadline. Re-anchor
    // instead of accumulating a backlog that would freeze subsequent UI work.
    if (_nextFrameUs == 0 ||
        nowUs < _nextFrameUs - 1 ||
        nowUs - _nextFrameUs > period * 2) {
      _nextFrameUs = nowUs + period;
    } else {
      _nextFrameUs += period;
    }
  }
}

/// Paces normal framework frame requests without skipping any build/paint phase.
/// Forced lifecycle/resize frames and startup warm-up retain Flutter's behavior.
class LauncherFrameBinding extends WidgetsFlutterBinding {
  final _clock = Stopwatch()..start();
  final _budget = UiFrameBudget();
  Timer? _pendingFrame;

  void setUiFps(int value) {
    final normalized = value == 30 || value == 60 ? value : 0;
    if (_budget.fps == normalized) return;
    final pending = _pendingFrame != null;
    _pendingFrame?.cancel();
    _pendingFrame = null;
    _budget.setFps(normalized);
    if (pending) scheduleFrame();
  }

  @override
  void scheduleFrame() {
    if (hasScheduledFrame || !framesEnabled || _pendingFrame != null) return;
    final delay = _budget.delayAt(_clock.elapsedMicroseconds);
    if (delay == Duration.zero) {
      super.scheduleFrame();
    } else {
      _pendingFrame = Timer(delay, () {
        _pendingFrame = null;
        super.scheduleFrame();
      });
    }
  }

  @override
  void handleBeginFrame(Duration? rawTimeStamp) {
    if (rawTimeStamp != null) {
      _pendingFrame?.cancel();
      _pendingFrame = null;
      _budget.frameBegan(_clock.elapsedMicroseconds);
    }
    super.handleBeginFrame(rawTimeStamp);
  }

  @override
  void scheduleForcedFrame() {
    _pendingFrame?.cancel();
    _pendingFrame = null;
    super.scheduleForcedFrame();
  }

  @override
  void handleAppLifecycleStateChanged(AppLifecycleState state) {
    super.handleAppLifecycleStateChanged(state);
    if (!framesEnabled) {
      _pendingFrame?.cancel();
      _pendingFrame = null;
    }
  }
}

class UiFrameRateController {
  static void apply(int fps) {
    final binding = WidgetsBinding.instance;
    if (binding is LauncherFrameBinding) binding.setUiFps(fps);
  }
}
