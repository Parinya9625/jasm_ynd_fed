import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rescu/feature/cart/widgets/cart_order_card.dart';

import 'cart_controller.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = controller.cartService;

    return Scaffold(
      appBar: AppBar(title: const Text('My bag')),
      body: RefreshIndicator(
        onRefresh: () {
          return Future.delayed(Duration(milliseconds: 500), () {
            cart.refresh();
          });
        },
        child: Obx(() {
          if (cart.items.isEmpty) {
            return const Center(child: Text('Your bag is empty'));
          }

          return CustomScrollView(
            slivers: [
              SliverPadding(padding: EdgeInsets.only(top: 8)),
              SliverList.builder(
                itemCount: cart.activeItems.length,
                itemBuilder: (context, index) {
                  final item = cart.activeItems[index];
                  return CartOrderCard(
                    item: item,
                    onTapDecrease: () {
                      cart.decrement(item.deal.id);
                    },
                    onTapIncrease: () {
                      cart.add(item.deal);
                    },
                    onFlashSaleExpired: () {
                      cart.refresh();
                    },
                    onReservedExpired: () {
                      cart.refresh();
                    },
                  );
                },
              ),
              if (cart.hasExpiredItems)
                SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: ListTile(
                        title: Text(
                          "Expired Items",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        trailing: OutlinedButton(
                          onPressed: cart.clearExpired,
                          child: Text("Clear"),
                        ),
                      ),
                    ),
                    SliverList.builder(
                      itemCount: cart.expiredItems.length,
                      itemBuilder: (context, index) {
                        final item = cart.expiredItems[index];
                        return CartOrderCard(
                          item: item,
                          onTapDelete: () {
                            cart.remove(item.deal.id);
                          },
                          onTapReReserve: () {
                            cart.retryReserve(item);
                          },
                          onFlashSaleExpired: () {
                            cart.refresh();
                          },
                          onReservedExpired: () {
                            cart.refresh();
                          },
                        );
                      },
                    ),
                  ],
                ),
              SliverPadding(padding: EdgeInsets.only(top: 8)),
            ],
          );
        }),
      ),
      bottomNavigationBar: Obx(() {
        if (cart.items.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          color: Colors.white,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 13)),
                  Text('฿${cart.total.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: FilledButton(
                  onPressed: controller.isCheckingOut.value || cart.activeItems.isEmpty ? null : controller.checkout,
                  child: controller.isCheckingOut.value
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Checkout'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
