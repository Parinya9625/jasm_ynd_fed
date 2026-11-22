import 'package:get/get.dart';

import '../model/cart_item_model.dart';
import '../model/deal_model.dart';
import '../util/log_service.dart';

/// App-wide cart. Lives for the whole session.
///
/// NOTE: the starter cart is purely local — it does not reserve stock on the
/// backend. See the "Reservations" feature task in PROBLEM.md.
class CartService extends GetxService {
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

    final existing = items.firstWhereOrNull((i) => i.deal.id == deal.id);
    if (existing != null) {
      if (existing.quantity >= deal.quantityLeft) {
        LogService.log('cart: cannot add more of deal ${deal.id}');
        return;
      }
      existing.quantity++;
      items.refresh();
    } else {
      items.add(CartItemModel(deal: deal));
    }
    _recount();
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
  }

  void remove(int dealId) {
    items.removeWhere((i) => i.deal.id == dealId);
    _recount();
  }

  void clear() {
    items.clear();
    _recount();
  }

  void clearActive() {
    items.removeWhere((i) => !i.isExpired);
    _recount();
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
