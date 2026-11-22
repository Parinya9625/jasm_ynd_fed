import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/app_config.dart';
import 'package:rescu/feature/shared_widget/flash_sale_deal_countdown.dart';
import 'package:rescu/feature/shared_widget/the_network_image.dart';
import 'package:rescu/model/deal_model.dart';
import 'package:rescu/routes/routes.dart';

class FlashDealCard extends StatefulWidget {
  const FlashDealCard({
    super.key,
    required this.deal,
  });

  final DealModel deal;

  @override
  State<FlashDealCard> createState() => _FlashDealCardState();
}

class _FlashDealCardState extends State<FlashDealCard> {
  late bool _isExpired;

  @override
  void initState() {
    super.initState();
    _isExpired = _checkExpired();
  }

  @override
  void didUpdateWidget(FlashDealCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.deal.id != widget.deal.id || oldWidget.deal.flashSaleEndsAt != widget.deal.flashSaleEndsAt) {
      _isExpired = _checkExpired();
    }
  }

  bool _checkExpired() {
    return widget.deal.isFlashSaleExpired;
  }

  void _onCountdownExpired() {
    if (!mounted || _isExpired) return;
    setState(() {
      _isExpired = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        color: Colors.white,
        elevation: 0.5,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          foregroundDecoration: _isExpired
              ? BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                )
              : null,
          child: InkWell(
            onTap: _isExpired
                ? null
                : () => Get.toNamed(
                      Routes.dealRoute(widget.deal.id, source: 'flash_rail'),
                      arguments: widget.deal,
                    ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TheNetworkImage(url: widget.deal.imageUrl, height: 90, width: double.infinity),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.deal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(widget.deal.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('฿${widget.deal.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppConfig.primaryGreen)),
                          const Spacer(),
                          FlashSaleDealCountdown(
                            deal: widget.deal,
                            onExpired: _onCountdownExpired,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
