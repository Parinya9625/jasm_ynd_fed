import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/service/analytics_service.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DealImpressionTracker extends StatefulWidget {
  const DealImpressionTracker({
    super.key,
    required this.id,
    required this.position,
    required this.source,
    required this.child,
  });

  final int id;
  final int position;
  final ImpressionSource source;
  final Widget child;

  @override
  State<DealImpressionTracker> createState() => _DealImpressionTrackerState();
}

class _DealImpressionTrackerState extends State<DealImpressionTracker> {
  late Key _detectorKey;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _detectorKey = _createKey();
  }

  @override
  void didUpdateWidget(DealImpressionTracker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.id != widget.id || oldWidget.source != widget.source) {
      _detectorKey = _createKey();
      _stopTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: _detectorKey,
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= 0.5) {
          _startTimer();
        } else {
          _stopTimer();
        }
      },
      child: widget.child,
    );
  }

  Key _createKey() {
    return ValueKey('impression_deal_${widget.id}_${widget.source.name}');
  }

  void _startTimer() {
    if (_timer != null) return;

    _timer = Timer(const Duration(seconds: 1), () {
      _timer = null;
      if (!mounted) return;

      Get.find<AnalyticsService>().logDealImpression(
        DealImpressionEvent(
          id: widget.id,
          position: widget.position,
          source: widget.source,
        ),
      );
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
