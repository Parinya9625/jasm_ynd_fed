import 'package:flutter/material.dart';
import 'package:rescu/app_config.dart';
import 'package:rescu/feature/shared_widget/flash_sale_deal_countdown.dart';
import 'package:rescu/feature/shared_widget/reservation_countdown.dart';
import 'package:rescu/feature/shared_widget/the_network_image.dart';
import 'package:rescu/model/cart_item_model.dart';
import 'package:rescu/model/reservation_model.dart';

class CartOrderCard extends StatefulWidget {
  const CartOrderCard({
    super.key,
    required this.item,
    this.onTapIncrease,
    this.onTapDecrease,
    this.onTapDelete,
    this.onFlashSaleExpired,
    this.onReservedExpired,
  });

  final CartItemModel item;
  final VoidCallback? onTapIncrease;
  final VoidCallback? onTapDecrease;
  final VoidCallback? onTapDelete;
  final VoidCallback? onFlashSaleExpired;
  final VoidCallback? onReservedExpired;

  @override
  State<CartOrderCard> createState() => _CartOrderCardState();
}

class _CartOrderCardState extends State<CartOrderCard> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.white,
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              children: [
                TheNetworkImage(
                  url: item.deal.imageUrl,
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.deal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                      Text(item.deal.storeName, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                      Row(
                        spacing: 8,
                        children: [
                          if (!item.deal.isFlashSaleExpired)
                            Text('฿${item.deal.price.toStringAsFixed(0)} each',
                                style: const TextStyle(
                                    fontSize: 13, color: AppConfig.primaryGreen, fontWeight: FontWeight.w600)),
                          if (item.deal.isFlashSale)
                            FlashSaleDealCountdown(
                              deal: item.deal,
                              onExpired: widget.onFlashSaleExpired,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (item.isExpired) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.cancel_outlined),
                        onPressed: widget.onTapDelete,
                      ),
                    ] else ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: widget.onTapDecrease,
                      ),
                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: widget.onTapIncrease,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            if (item.reservation case ReservationModel reservation when !widget.item.isExpired)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ReservationCountdown(
                    reservation: reservation,
                    onExpired: widget.onReservedExpired,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
