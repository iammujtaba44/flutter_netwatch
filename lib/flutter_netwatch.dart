/// Production-grade Flutter HTTP inspector.
///
/// Add `NetWatch.builder` to your `MaterialApp.builder` and the matching
/// interceptor (Dio/http/Chopper) to your HTTP client.
library flutter_netwatch;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'src/core/netwatch_core.dart';
import 'src/interceptors/nw_chopper_interceptor.dart';
import 'src/interceptors/nw_dio_interceptor.dart';
import 'src/interceptors/nw_http_client.dart';
import 'src/models/nw_config.dart';
import 'src/models/nw_transaction.dart';
import 'src/navigation/nw_navigator_observer.dart';
import 'src/ui/nw_builder_wrapper.dart';

export 'src/core/netwatch_core.dart' show NetWatchCore;
export 'src/exporters/nw_curl_exporter.dart';
export 'src/exporters/nw_postman_exporter.dart';
export 'src/exporters/nw_share_exporter.dart';
export 'src/interceptors/nw_chopper_interceptor.dart';
export 'src/interceptors/nw_dio_interceptor.dart';
export 'src/interceptors/nw_http_client.dart';
export 'src/masking/nw_masker.dart';
export 'src/models/nw_config.dart';
export 'src/models/nw_request.dart';
export 'src/models/nw_response.dart';
export 'src/models/nw_security_analysis.dart';
export 'src/models/nw_transaction.dart';
export 'src/models/nw_transaction_status.dart';
export 'src/navigation/nw_navigator_observer.dart';
export 'src/storage/nw_memory_storage.dart';
export 'src/storage/nw_storage.dart';

class NetWatch {
  NetWatch._();

  static void initialize({NetWatchConfig config = const NetWatchConfig()}) {
    NetWatchCore.instance.initialize(config: config);
  }

  static GlobalKey<NavigatorState> get navigatorKey =>
      NetWatchCore.instance.navigatorKey;

  static NWNavigatorObserver get observer => NetWatchCore.instance.observer;

  static NWDioInterceptor get dioInterceptor => NWDioInterceptor();

  static Interceptor get dio => NWDioInterceptor();

  static http.Client httpClient([http.Client? inner]) =>
      NWHttpClient(inner ?? http.Client());

  static NWChopperInterceptor get chopperInterceptor => NWChopperInterceptor();

  static TransitionBuilder get builder {
    return (BuildContext context, Widget? child) {
      if (kReleaseMode) {
        return child ?? const SizedBox.shrink();
      }
      return NWBuilderWrapper(child: child);
    };
  }

  static void open() => NetWatchCore.instance.openInspector();

  static void clear() => NetWatchCore.instance.clearAll();

  static List<NWTransaction> get transactions =>
      NetWatchCore.instance.storage.getAll();

  static Stream<List<NWTransaction>> get transactionStream =>
      NetWatchCore.instance.transactionStream;

  static bool get isActive => NetWatchCore.instance.isActive;
}
