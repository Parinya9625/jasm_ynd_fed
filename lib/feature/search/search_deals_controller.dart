import 'dart:async';

import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  Timer? _debounceTimer;
  // NOTE: Track latest search
  int _searchID = 0;

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final currentSearchID = ++_searchID;

    final trimQuery = query.trim();
    if (trimQuery.isEmpty) {
      results.clear();
      isLoading.value = false;
      hasSearched.value = false;
      return;
    }

    isLoading.value = true;
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _search(trimQuery, searchID: currentSearchID);
    });
  }

  Future<void> _search(String query, {int searchID = 0}) async {
    isLoading.value = true;
    hasSearched.value = true;

    try {
      final found = await dealRepo.search(query);
      if (_searchID != searchID) return;

      results.assignAll(found);
    } catch (e) {
      LogService.error('search failed', e);
    } finally {
      if (_searchID == searchID) {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }
}
