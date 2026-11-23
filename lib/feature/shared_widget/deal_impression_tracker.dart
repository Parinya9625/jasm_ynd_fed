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
  Timer? _timer;

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = ValueKey('impression_deal_${widget.id}_${widget.source.name}_${widget.position}');

    return VisibilityDetector(
      key: key,
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

  void _startTimer() {
    if (_timer != null) return;

    _timer = Timer(const Duration(seconds: 1), () {
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
