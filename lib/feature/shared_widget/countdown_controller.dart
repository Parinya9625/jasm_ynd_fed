import 'dart:async';

import 'package:get/get.dart';

class CountdownController extends GetxController {
  Timer? _timer;
  Timer? _shortTimer;
  DateTime? _endAt;
  Function()? _onExpired;

  final text = "00:00".obs;
  final isExpired = false.obs;

  void start(DateTime endAt) {
    // NOTE: prevent restart if rebuild with same datetime
    if (_endAt == endAt && (_timer?.isActive ?? false)) return;

    _cancelTimer();
    _endAt = endAt;

    final diff = endAt.difference(DateTime.now());
    if (diff <= Duration.zero) {
      _updateRemaining(Duration.zero);
      return;
    }

    _updateRemaining(diff);

    // NOTE: handle short duration
    _shortTimer = Timer(diff + const Duration(milliseconds: 20), () {
      if (isClosed) return;
      _cancelTimer();
      _endAt = null;
      _updateRemaining(Duration.zero);
      _onExpired?.call();
    });

    if (diff <= const Duration(seconds: 1)) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }

      final diff = endAt.difference(DateTime.now());
      if (diff <= Duration.zero) {
        stop();
        _onExpired?.call();
      } else {
        _updateRemaining(diff);
      }
    });
  }

  void stop() {
    _cancelTimer();
    _updateRemaining(Duration.zero);
    _endAt = null;
  }

  void setOnExpiredTrigger(Function()? onExpired) {
    _onExpired = onExpired;
  }

  void _updateRemaining(Duration duration) {
    isExpired.value = duration <= Duration.zero;

    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');

    if (duration.inHours >= 1) {
      final h = duration.inHours.toString().padLeft(2, '0');
      text.value = "$h:$m:$s";
      return;
    }

    text.value = "$m:$s";
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _shortTimer?.cancel();
    _shortTimer = null;
  }

  @override
  void onClose() {
    _cancelTimer();
    super.onClose();
  }
}
