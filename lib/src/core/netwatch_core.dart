import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../masking/nw_masker.dart';
import '../models/nw_config.dart';
import '../models/nw_response.dart';
import '../models/nw_transaction.dart';
import '../navigation/nw_navigator_observer.dart';
import '../navigation/nw_overlay_router.dart';
import '../notification/nw_notification_layer.dart';
import '../storage/nw_memory_storage.dart';
import '../storage/nw_storage.dart';
import 'nw_transaction_controller.dart';

class NetWatchCore {
  NetWatchCore._();

  static final NetWatchCore instance = NetWatchCore._();

  NetWatchConfig _config = const NetWatchConfig();
  NWStorage _storage = NWMemoryStorage(maxSize: 200);
  NWMasker _masker = const NWMasker(
    sensitiveHeaders: NetWatchConfig.defaultSensitiveHeaders,
    sensitiveBodyFields: NetWatchConfig.defaultSensitiveBodyFields,
    sensitiveQueryParams: NetWatchConfig.defaultSensitiveQueryParams,
  );

  GlobalKey<OverlayState>? _overlayKey;
  GlobalKey<NavigatorState>? _navigatorKey;
  final NWNavigatorObserver _observer = NWNavigatorObserver();
  final NWTransactionController _txController = NWTransactionController();
  final ValueNotifier<int> unseenCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> maskingEnabled = ValueNotifier<bool>(true);

  bool _initialized = false;

  NetWatchConfig get config => _config;
  NWStorage get storage => _storage;
  NWMasker get masker => _masker;
  NWNavigatorObserver get observer => _observer;
  bool get isInitialized => _initialized;
  bool get isActive => _initialized && _config.enabled && !kReleaseMode;

  GlobalKey<NavigatorState> get navigatorKey =>
      _navigatorKey ??= GlobalKey<NavigatorState>();

  GlobalKey<OverlayState>? get overlayKey => _overlayKey;

  Stream<List<NWTransaction>> get transactionStream => _txController.stream;

  void initialize({required NetWatchConfig config}) {
    if (kReleaseMode) {
      _config = config.copyWith(enabled: false);
      _initialized = true;
      return;
    }
    _config = config;
    _storage = NWMemoryStorage(maxSize: config.maxTransactions);
    _masker = NWMasker(
      sensitiveHeaders: config.sensitiveHeaders,
      sensitiveBodyFields: config.sensitiveBodyFields,
      sensitiveQueryParams: config.sensitiveQueryParams,
    );
    maskingEnabled.value = config.maskSensitiveData;
    _initialized = true;
  }

  void registerOverlay(GlobalKey<OverlayState> key) {
    _overlayKey = key;
  }

  void addTransaction(NWTransaction transaction) {
    if (!isActive) return;
    _storage.add(transaction);
    _txController.emit(_storage.getAll());
    if (!NWOverlayRouter.hasActive) {
      unseenCount.value = unseenCount.value + 1;
    }
    _showNotification(transaction);
  }

  void updateTransaction(String id, NWResponse response) {
    if (!isActive) return;
    _storage.update(id, response);
    _txController.emit(_storage.getAll());
    final updated = _storage.getById(id);
    if (updated != null) {
      _showNotification(updated, isUpdate: true);
    }
  }

  void removeTransaction(String id) {
    if (!isActive) return;
    _storage.remove(id);
    _txController.emit(_storage.getAll());
  }

  void clearAll() {
    _storage.clear();
    _txController.emit(<NWTransaction>[]);
    unseenCount.value = 0;
  }

  void resetUnseen() {
    unseenCount.value = 0;
  }

  void setMasking(bool enabled) {
    maskingEnabled.value = enabled;
  }

  void openInspector() {
    final key = _overlayKey;
    if (key == null || key.currentState == null) return;
    resetUnseen();
    NWOverlayRouter.openInspector(key);
  }

  void openTransactionDetail(NWTransaction transaction) {
    final key = _overlayKey;
    if (key == null || key.currentState == null) return;
    NWOverlayRouter.openTransactionDetail(key, transaction);
  }

  void _showNotification(NWTransaction transaction, {bool isUpdate = false}) {
    if (!_config.showNotifications) return;
    final key = _overlayKey;
    if (key == null || key.currentState == null) return;
    if (NWOverlayRouter.hasActive) return;
    NWNotificationLayer.show(key, transaction);
  }
}
