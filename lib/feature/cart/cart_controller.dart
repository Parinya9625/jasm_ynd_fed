import 'package:get/get.dart';

import '../../repository/order_repo.dart';
import '../../service/api_exception.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class CartController extends GetxController {
  final CartService cartService;
  final OrderRepo orderRepo;

  CartController({required this.cartService, required this.orderRepo});

  final isCheckingOut = false.obs;

  @override
  void onInit() {
    super.onInit();
    cartService.refresh();
  }

  Future<void> checkout() async {
    if (isCheckingOut.value) return;

    if (cartService.isExpiredItemChanged) {
      isCheckingOut.value = true;
      await Future.delayed(Duration(milliseconds: 500), () {
        cartService.refresh();
      });
      if (isClosed) return;
      isCheckingOut.value = false;

      Get.snackbar(
        "Warning",
        "Some item has been expired",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (cartService.activeItems.isEmpty) return;

    isCheckingOut.value = true;
    try {
      final order = await orderRepo.checkout(cartService.activeItems.toList());
      cartService.clearActive();
      Get.snackbar(
        'Order confirmed',
        'Order #${order.id} — pick up soon!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (e) {
      LogService.error('checkout failed', e);
      switch (e.statusCode) {
        case 410:
          cartService.refresh();
          Get.snackbar(
            "Reservation expired",
            "Re-reserve or remove expired items to continue.",
            snackPosition: SnackPosition.BOTTOM,
          );
        default:
          Get.snackbar(
            'Checkout failed',
            e.message,
            snackPosition: SnackPosition.BOTTOM,
          );
      }
    } finally {
      if (!isClosed) {
        isCheckingOut.value = false;
      }
    }
  }
}
