import 'dart:async';

/// Generic timer-based debounce helper. Useful for autosave-on-edit,
/// search-as-you-type, or any "wait for the user to stop typing" flow.
///
/// Call [flush] from an `AppLifecycleAwareMixin.onPaused()` override (or
/// anywhere else a pending change must not be lost) to run the scheduled
/// action immediately instead of waiting out the delay.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 600)});

  final Duration delay;

  Timer? _timer;
  Future<void> Function()? _pending;

  /// Schedules [action] to run after [delay], cancelling any previously
  /// scheduled action that hasn't run yet.
  void schedule(Future<void> Function() action) {
    _timer?.cancel();
    _pending = action;
    _timer = Timer(delay, () {
      _pending = null;
      action();
    });
  }

  /// Runs the pending action immediately, if any, and cancels the timer.
  Future<void> flush() async {
    _timer?.cancel();
    final action = _pending;
    _pending = null;
    if (action != null) await action();
  }

  void dispose() {
    _timer?.cancel();
    _pending = null;
  }
}
