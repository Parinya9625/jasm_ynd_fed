import 'package:get/get.dart';
import 'package:rescu/model/reservation_model.dart';
import 'package:rescu/repository/order_repo.dart';
import 'package:rescu/service/api_exception.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../util/log_service.dart';

/// App-wide cart. Lives for the whole session.
///
/// NOTE: the starter cart is purely local — it does not reserve stock on the
/// backend. See the "Reservations" feature task in PROBLEM.md.
class CartService extends GetxService {
  CartService({required this.orderRepo});

  final OrderRepo orderRepo;

  final items = <CartItemModel>[].obs;
  final itemCount = 0.obs;
  int _lastExpiredItemCount = 0;

  List<CartItemModel> get activeItems {
    return items.where((i) => !i.isExpired).toList();
  }

  List<CartItemModel> get expiredItems {
    return items.where((i) => i.isExpired).toList();
  }

  bool get hasExpiredItems => expiredItems.isNotEmpty;

  bool get isExpiredItemChanged {
    return expiredItems.length != _lastExpiredItemCount;
  }

  void add(DealModel deal) {
    if (deal.isFlashSaleExpired) return;

    CartItemModel? existing = items.firstWhereOrNull((i) => i.deal.id == deal.id);
    if (existing != null) {
      if (existing.quantity >= deal.quantityLeft) {
        Get.snackbar(
          "Fail to added",
          "Can't add more of '${deal.name}' deal",
          snackPosition: SnackPosition.BOTTOM,
        );
        LogService.log('cart: cannot add more of deal ${deal.id}');
        return;
      }
      existing.quantity++;
      items.refresh();
    } else {
      existing = CartItemModel(deal: deal);
      items.add(existing);
    }
    _recount();
    updateReservation(existing);
  }

  void decrement(int dealId) {
    final existing = items.firstWhereOrNull((i) => i.deal.id == dealId);
    if (existing == null) return;
    existing.quantity--;
    if (existing.quantity <= 0) {
      items.removeWhere((i) => i.deal.id == dealId);
    } else {
      items.refresh();
    }
    _recount();
    updateReservation(existing);
  }

  void updateReservation(CartItemModel item) async {
    ReservationModel? reservation = item.reservation;

    if (item.reservation case ReservationModel rsv) {
      // EXISTING ITEM
      final quantity = item.quantity;
      try {
        if (quantity > 0) {
          reservation = await orderRepo.reserve(item.deal.id, quantity: quantity);

          final currentItem = items.firstWhereOrNull((i) => i.deal.id == item.deal.id);
          if (currentItem == null || currentItem.quantity != quantity) {
            await _releaseReservation(reservation.id);
            return;
          }
        }

        await _releaseReservation(rsv.id);
      } on ApiException catch (e) {
        _showReservationError(e, isIncrease: quantity > rsv.quantity);
        reservation = rsv;
        item.quantity = rsv.quantity;
      }
    } else {
      // NEW ITEM
      try {
        final quantity = item.quantity;
        reservation = await orderRepo.reserve(item.deal.id, quantity: quantity);

        final currentItem = items.firstWhereOrNull((i) => i.deal.id == item.deal.id);
        if (currentItem == null || currentItem.quantity != quantity) {
          await _releaseReservation(reservation.id);
          return;
        }
      } on ApiException catch (e) {
        remove(item.deal.id);
        _showReservationError(e);
        return;
      }
    }

    item.reservation = reservation;
    refresh();
  }

  Future<void> _releaseReservation(String? reservationId) async {
    if (reservationId == null) return;
    try {
      await orderRepo.releaseReservation(reservationId);
    } catch (e) {
      LogService.error("fail to release reservation $reservationId: $e");
    }
  }

  void _showReservationError(ApiException e, {bool isIncrease = true}) {
    switch (e.statusCode) {
      case 409 when isIncrease:
        Get.snackbar(
          "Reserved fail",
          "Sorry, someone just grabbed the last one.",
          snackPosition: SnackPosition.BOTTOM,
        );
      case 409:
        // Note: when try to decrease but api is error with 409
        Get.snackbar(
          "Reserved fail",
          "Sorry, couldn't update your reserved quantity.",
          snackPosition: SnackPosition.BOTTOM,
        );
      default:
        Get.snackbar(
          "Oops",
          "Something went wrong, please try again later.",
          snackPosition: SnackPosition.BOTTOM,
        );
    }
  }

  //

  void remove(int dealId) {
    final item = items.firstWhereOrNull((i) => i.deal.id == dealId);
    items.removeWhere((i) => i.deal.id == dealId);
    _recount();
    _releaseReservation(item?.reservation?.id);
  }

  void clear() {
    final rid = items.map((i) => i.reservation?.id).toList();
    items.clear();
    _recount();
    for (final id in rid) {
      _releaseReservation(id);
    }
  }

  void clearActive() {
    final rid = activeItems.map((i) => i.reservation?.id).toList();
    items.removeWhere((i) => !i.isExpired);
    _recount();
    for (final id in rid) {
      _releaseReservation(id);
    }
  }

  void clearExpired() {
    items.removeWhere((i) => i.isExpired);
    _recount();
  }

  void refresh() {
    items.refresh();
    _recount();
  }

  num get total => activeItems.fold(0, (sum, i) => sum + i.lineTotal);

  void _recount() {
    itemCount.value = activeItems.fold(0, (sum, i) => sum + i.quantity);
    _lastExpiredItemCount = expiredItems.length;
  }
}
