import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/shared_widget/countdown_controller.dart';
import 'package:rescu/model/deal_model.dart';

class FlashSaleDealCountdown extends StatefulWidget {
  const FlashSaleDealCountdown({
    super.key,
    required this.deal,
    this.onExpired,
  });

  final DealModel deal;
  final Function()? onExpired;

  @override
  State<FlashSaleDealCountdown> createState() => _FlashSaleDealCountdownState();
}

class _FlashSaleDealCountdownState extends State<FlashSaleDealCountdown> {
  late final CountdownController _controller;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(FlashSaleDealCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller.setOnExpiredTrigger(widget.onExpired);
    if (oldWidget.deal.id != widget.deal.id || oldWidget.deal.flashSaleEndsAt != widget.deal.flashSaleEndsAt) {
      _syncTimer();
    }
  }

  @override
  void dispose() {
    _controller.onClose();
    super.dispose();
  }

  void _setupController() {
    _controller = CountdownController()..onInit();
    _controller.setOnExpiredTrigger(widget.onExpired);
    _syncTimer();
  }

  void _syncTimer() {
    if (widget.deal.flashSaleEndsAt case DateTime endAt) {
      _controller.start(endAt);
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Obx(() {
        return Text(
          _controller.isExpired.value ? "Expired" : _controller.text.value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.red.shade700,
            fontFeatures: [
              FontFeature.tabularFigures(),
            ],
          ),
        );
      }),
    );
  }
}
