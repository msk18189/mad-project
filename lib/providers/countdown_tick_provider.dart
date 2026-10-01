import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lifecycle-aware timer controller that pauses ticking when backgrounded
/// and immediately triggers a recalculation using `DateTime.now()` on resume.
class _LifecycleTicker with WidgetsBindingObserver {
  final StreamController<DateTime> _controller;
  Timer? _timer;
  bool _isBackgrounded = false;

  _LifecycleTicker(this._controller) {
    WidgetsBinding.instance.addObserver(this);
    // Emit immediate current time upon startup
    _controller.add(DateTime.now());
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isBackgrounded && !_controller.isClosed) {
        _controller.add(DateTime.now());
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _isBackgrounded = true;
      _stopTimer();
    } else if (state == AppLifecycleState.resumed) {
      _isBackgrounded = false;
      // Immediately emit true current time upon resume (Section 10 & 48)
      if (!_controller.isClosed) {
        _controller.add(DateTime.now());
      }
      _startTimer();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _controller.close();
  }
}

/// Centralized StreamProvider emitting the current DateTime every second.
/// Exactly ONE periodic timer exists across the entire app.
final countdownTickProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  final ticker = _LifecycleTicker(controller);

  ref.onDispose(() {
    ticker.dispose();
  });

  return controller.stream;
});

/// Direct synchronous provider of the current time, driven by the centralized ticker
final currentDateTimeProvider = Provider<DateTime>((ref) {
  final tickAsync = ref.watch(countdownTickProvider);
  return tickAsync.value ?? DateTime.now();
});
