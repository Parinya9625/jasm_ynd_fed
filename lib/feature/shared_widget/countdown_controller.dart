import 'dart:async';

import 'package:get/get.dart';

class CountdownController extends GetxController {
  Timer? _timer;
  DateTime? _endAt;
  Function()? _onExpired;
  Worker? _expiredWorker;

  final text = "00:00".obs;
  final isExpired = true.obs;

  @override
  void onInit() {
    super.onInit();

    _expiredWorker = ever<bool>(isExpired, _onExpireUpdate);
  }

  void start(DateTime endAt) {
    // NOTE: prevent restart if rebuild with same datetime
    if (_endAt == endAt && (_timer?.isActive ?? false)) return;

    _timer?.cancel();
    _endAt = endAt;

    final diff = endAt.difference(DateTime.now());
    if (diff <= Duration.zero) {
      _updateRemaining(Duration.zero);
      return;
    }

    _updateRemaining(diff);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }

      final diff = endAt.difference(DateTime.now());
      if (diff <= Duration.zero) {
        stop();
      } else {
        _updateRemaining(diff);
      }
    });
  }

  void stop() {
    _timer?.cancel();
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

  void _onExpireUpdate(bool isExpired) {
    if (isExpired && !isClosed) {
      _onExpired?.call();
    }
  }

  @override
  void onClose() {
    _expiredWorker?.dispose();
    _timer?.cancel();
    super.onClose();
  }
}
