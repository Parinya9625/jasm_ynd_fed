import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:rescu/service/fake_api_service.dart';

import '../util/log_service.dart';

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime at;

  AnalyticsEvent(this.name, this.properties) : at = DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'properties': properties,
        'at': at.toIso8601String(),
      };
}

enum ImpressionSource {
  home("home_feed"),
  homePickToday("home_feed_pick_today"),
  flashSaleSection("flash_rail"),
  search("search"),
  unknown("unknown");

  const ImpressionSource(this.name);
  final String name;
}

class DealImpressionEvent {
  const DealImpressionEvent({
    required this.id,
    required this.position,
    required this.source,
  });

  final int id;
  final int position;
  final ImpressionSource source;

  static const name = "deal_impression";
  static const kDealID = "deal_id";

  Map<String, dynamic> toJson() {
    return {
      kDealID: id,
      "source": source.name,
      "position": position,
    };
  }

  AnalyticsEvent toAnalyticsEvent() {
    return AnalyticsEvent(name, toJson());
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

/// In-memory analytics sink. Events are visible on the debug screen
/// (overflow menu on Home -> "Analytics debug") and in the console.
///
/// The "Impression tracking" feature task builds on top of this service.
class AnalyticsService extends GetxService {
  AnalyticsService({
    required this.api,
  });

  final FakeApiService api;

  final events = <AnalyticsEvent>[].obs;

  final _queueDealImpressions = <DealImpressionEvent>[].obs;
  Timer? _timerDealImpressions;
  bool _isSendingDealImpressions = false;
  late final Worker _workerQueueDealImpressions;
  final _kSendDealImpressionsBatchSize = 10;
  final _kSendDealImpressionsTime = Duration(seconds: 15);

  @override
  void onInit() {
    super.onInit();

    _workerQueueDealImpressions = ever(_queueDealImpressions, (_) async {
      if (_isSendingDealImpressions) return;

      if (_queueDealImpressions.length >= _kSendDealImpressionsBatchSize) {
        _sendBatchDealImpressions();
      } else {
        _setupDealImpressionsTimer();
      }
    });
  }

  @override
  void onClose() {
    _timerDealImpressions?.cancel();
    _workerQueueDealImpressions.dispose();
    super.onClose();
  }

  void logEvent(String name, [Map<String, dynamic> properties = const {}]) {
    final event = AnalyticsEvent(name, properties);
    events.add(event);
    LogService.log('analytics: $name $properties');
  }

  void logDealImpression(DealImpressionEvent event) {
    if (event case DealImpressionEvent evt when _isDuplicatedDealImpression(evt)) return;

    final analytic = event.toAnalyticsEvent();
    events.add(analytic);
    _queueDealImpressions.add(event);
    LogService.log(
      'analytics: ${analytic.name} ${analytic.properties}',
    );
  }

  bool _isDuplicatedDealImpression(DealImpressionEvent event) {
    return events.any((e) {
      return e.name == DealImpressionEvent.name && e.properties[DealImpressionEvent.kDealID] == event.id;
    });
  }

  Future<void> _sendBatchDealImpressions() async {
    if (_queueDealImpressions.isEmpty || _isSendingDealImpressions) return;

    _timerDealImpressions?.cancel();
    _isSendingDealImpressions = true;

    final count = _queueDealImpressions.length >= _kSendDealImpressionsBatchSize
        ? _kSendDealImpressionsBatchSize
        : _queueDealImpressions.length;

    final impressions = _queueDealImpressions.sublist(0, count);
    final batchEvents = impressions.map((i) => i.toAnalyticsEvent().toJson()).toList();

    var isSuccess = false;
    try {
      await api.sendAnalyticsBatch(batchEvents);
      if (isClosed) return;

      final remaining = List<DealImpressionEvent>.from(_queueDealImpressions)..removeRange(0, count);
      _queueDealImpressions.assignAll(remaining);
      isSuccess = true;

      logEvent("deal_impressions_send_batch", {
        "send": impressions.map((i) => i.id).toList(),
        "remain": remaining.map((i) => i.id).toList(),
      });
    } catch (e, st) {
      LogService.error('analytics failed: $e\n$st');
    } finally {
      _isSendingDealImpressions = false;

      if (!isClosed && _queueDealImpressions.isNotEmpty) {
        if (isSuccess && _queueDealImpressions.length >= _kSendDealImpressionsBatchSize) {
          _sendBatchDealImpressions();
        } else {
          _setupDealImpressionsTimer();
        }
      }
    }
  }

  void _setupDealImpressionsTimer() {
    if ((_timerDealImpressions?.isActive ?? false) || _queueDealImpressions.isEmpty || _isSendingDealImpressions) {
      return;
    }

    _timerDealImpressions = Timer(_kSendDealImpressionsTime, () async {
      await _sendBatchDealImpressions();
    });
  }
}
