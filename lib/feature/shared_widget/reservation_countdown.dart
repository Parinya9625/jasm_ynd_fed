import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:rescu/feature/shared_widget/countdown_controller.dart';
import 'package:rescu/model/reservation_model.dart';

class ReservationCountdown extends StatefulWidget {
  const ReservationCountdown({
    super.key,
    this.enabled = true,
    required this.reservation,
    this.onExpired,
  });

  final bool enabled;
  final ReservationModel reservation;
  final Function()? onExpired;

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown> {
  late final CountdownController _controller;

  @override
  void initState() {
    super.initState();
    _setupController();
  }

  @override
  void didUpdateWidget(covariant ReservationCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    _controller.setOnExpiredTrigger(widget.onExpired);
    if (oldWidget.reservation.id != widget.reservation.id ||
        oldWidget.reservation.expiresAt != widget.reservation.expiresAt) {
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
    if (widget.reservation.expiresAt case DateTime endAt when !widget.reservation.isExpired && widget.enabled) {
      _controller.start(endAt);
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Text(
            "Reserved for",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          Obx(() {
            return Text(
              _controller.isExpired.value ? "Expired" : _controller.text.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFeatures: [
                  FontFeature.tabularFigures(),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
