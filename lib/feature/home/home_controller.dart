import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class HomeController extends GetxController {
  final DealRepo dealRepo;

  HomeController({required this.dealRepo});

  final deals = <DealModel>[].obs;
  final flashDeals = <DealModel>[].obs;
  final isLoading = true.obs;
  final todayOnly = false.obs;

  final scrollController = ScrollController();
  final refreshController = RefreshController();

  final showAppBarElevation = false.obs;
  final showFABScrollToTop = false.obs;
  final _showAppBarElevationThreshold = 4;
  final _showFABScrollToTopThreshold = 800;

  int _page = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;

  bool get hasMore => _page < _totalPages;

  List<DealModel> get visibleDeals =>
      todayOnly.value ? deals.where((d) => d.pickupWindow.isToday).toList() : deals.toList();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _initialLoad();
  }

  void _onScroll() {
    showAppBarElevation.value = scrollController.offset > _showAppBarElevationThreshold;
    showFABScrollToTop.value = scrollController.offset > _showFABScrollToTopThreshold;
  }

  Future<void> _initialLoad() async {
    isLoading.value = true;
    try {
      await Future.wait([refreshDeals(), _loadFlashDeals()]);
    } catch (e) {
      LogService.error('initial load failed', e);
    }
    isLoading.value = false;
  }

  Future<void> _loadFlashDeals() async {
    flashDeals.assignAll(await dealRepo.fetchFlashDeals());
  }

  Future<void> refreshDeals() async {
    _page = 1;
    final res = await dealRepo.fetchDeals(page: 1);
    if (isClosed) return;

    _totalPages = res.totalPages;
    deals.assignAll(res.items);
    refreshController.refreshCompleted();
    refreshController.resetNoData();
  }

  Future<void> loadMore() async {
    if (refreshController.isRefresh || _isFetchingMore) {
      refreshController.loadComplete();
      return;
    }
    if (!hasMore) {
      refreshController.loadNoData();
      return;
    }
    _isFetchingMore = true;
    final loadedPage = ++_page;
    try {
      final res = await dealRepo.fetchDeals(page: _page);
      if (_page != loadedPage || isClosed) return;

      _totalPages = res.totalPages;
      deals.addAll(res.items);
    } catch (e) {
      LogService.error('loadMore failed', e);
      _page--;
    } finally {
      if (!isClosed) {
        _isFetchingMore = false;
        refreshController.loadComplete();
      }
    }
  }

  void scrollToTop() {
    scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  void onClose() {
    scrollController.dispose();
    refreshController.dispose();
    super.onClose();
  }
}
