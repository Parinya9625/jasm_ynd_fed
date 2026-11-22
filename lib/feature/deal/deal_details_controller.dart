import 'package:get/get.dart';
import 'package:rescu/routes/routes.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/analytics_service.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController with StateMixin<DealModel> {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;

  final isDealExpired = false.obs;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
  });

  late final DealModel deal;

  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;

  Worker? _recheckWorker;

  @override
  void onInit() async {
    super.onInit();
    await _prepareDeal();
  }

  @override
  void onClose() {
    _recheckWorker?.dispose();
    super.onClose();
  }

  Future<void> _prepareDeal() async {
    change(null, status: RxStatus.loading());

    if (Get.arguments case DealModel arg) {
      deal = arg;
      change(deal, status: RxStatus.success());
    } else {
      final id = int.tryParse(Get.parameters["id"] ?? "");
      if (id == null) return change(null, status: RxStatus.error("invalid deal id"));

      try {
        deal = await dealRepo.fetchById(id);
        if (isClosed) return;

        change(deal, status: RxStatus.success());
      } catch (e) {
        if (isClosed) return;
        return change(null, status: RxStatus.error(e.toString()));
      }
    }

    _quantityLeft.value = deal.quantityLeft;
    analytics.logEvent('deal_details_view', {
      'deal_id': deal.id,
      'source': Get.parameters['source'] ?? 'unknown',
    });
    // Whenever the cart changes, re-check this deal's remaining stock so the
    // details screen never shows stale availability.
    _recheckWorker = ever(cartService.itemCount, (_) => _recheckAvailability());

    if (deal.flashSaleEndsAt case DateTime endAt) {
      isDealExpired.value = !DateTime.now().isBefore(endAt);
    }
  }

  Future<void> _recheckAvailability() async {
    LogService.log('re-checking availability for deal ${deal.id}');
    final fresh = await dealRepo.fetchById(deal.id);
    if (isClosed) return;

    _quantityLeft.value = fresh.quantityLeft;
  }

  void addToCart() {
    cartService.add(deal);
    Get.snackbar(
      'Added to bag',
      '${deal.name} — pick up ${deal.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void onFlashSaleExpired() {
    isDealExpired.value = true;
  }

  void safeGoBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      Get.offAllNamed(Routes.home);
    }
  }
}
