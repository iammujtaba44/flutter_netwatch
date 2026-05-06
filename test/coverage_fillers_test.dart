import 'dart:convert';

import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('NetWatchConfig.copyWith', () {
    test('returns identical config when no overrides', () {
      const c = NetWatchConfig();
      final copy = c.copyWith();
      expect(copy.enabled, c.enabled);
      expect(copy.maxTransactions, c.maxTransactions);
      expect(copy.performanceBudgetMs, c.performanceBudgetMs);
    });

    test('overrides each field', () {
      const c = NetWatchConfig();
      final copy = c.copyWith(
        enabled: false,
        maxTransactions: 50,
        showFloatingBubble: false,
        showNotifications: false,
        initialBubblePosition: const Offset(1, 2),
        notificationDuration: const Duration(seconds: 5),
        maskSensitiveData: false,
        sensitiveHeaders: const ['x'],
        sensitiveBodyFields: const ['y'],
        sensitiveQueryParams: const ['z'],
        performanceBudgetMs: 250,
      );
      expect(copy.enabled, false);
      expect(copy.maxTransactions, 50);
      expect(copy.showFloatingBubble, false);
      expect(copy.showNotifications, false);
      expect(copy.initialBubblePosition, const Offset(1, 2));
      expect(copy.notificationDuration, const Duration(seconds: 5));
      expect(copy.maskSensitiveData, false);
      expect(copy.sensitiveHeaders, ['x']);
      expect(copy.sensitiveBodyFields, ['y']);
      expect(copy.sensitiveQueryParams, ['z']);
      expect(copy.performanceBudgetMs, 250);
    });
  });

  group('NetWatch facade', () {
    setUp(() {
      NetWatch.initialize(config: const NetWatchConfig());
      NetWatchCore.instance.clearAll();
      NetWatchCore.instance.clearReplayers();
    });

    test('exposes interceptor instances', () {
      expect(NetWatch.dioInterceptor, isA<NWDioInterceptor>());
      expect(NetWatch.dio, isA<NWDioInterceptor>());
      expect(NetWatch.chopperInterceptor, isA<NWChopperInterceptor>());
    });

    test('httpClient wraps a provided client', () {
      final client = NetWatch.httpClient(http.Client());
      expect(client, isA<NWHttpClient>());
      client.close();
    });

    test('httpClient creates a default inner client when none given', () {
      final client = NetWatch.httpClient();
      expect(client, isA<NWHttpClient>());
      client.close();
    });

    test('isActive reflects initialization', () {
      expect(NetWatch.isActive, true);
    });

    test('observer returns the singleton observer', () {
      expect(NetWatch.observer, NetWatchCore.instance.observer);
    });

    test('navigatorKey is non-null and stable across reads', () {
      final a = NetWatch.navigatorKey;
      final b = NetWatch.navigatorKey;
      expect(identical(a, b), true);
    });

    test('clear empties storage', () {
      _addDummyTx();
      expect(NetWatch.transactions.length, 1);
      NetWatch.clear();
      expect(NetWatch.transactions, isEmpty);
    });

    test('transactionStream emits the current list', () async {
      final emitted = <int>[];
      final sub =
          NetWatch.transactionStream.listen((list) => emitted.add(list.length));
      _addDummyTx();
      _addDummyTx();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await sub.cancel();
      expect(emitted, isNotEmpty);
      expect(emitted.last, greaterThanOrEqualTo(2));
    });

    test('hasReplayer flips when a replayer is registered', () {
      expect(NetWatch.hasReplayer, false);
      NetWatch.registerReplayer(NWCustomReplayer(
        canHandle: (_) => true,
        replay: (_) async {},
      ));
      expect(NetWatch.hasReplayer, true);
    });
  });

  group('NetWatchCore mutations', () {
    setUp(() {
      NetWatch.initialize(config: const NetWatchConfig());
      NetWatchCore.instance.clearAll();
    });

    test('removeTransaction removes by id', () {
      final tx = _makeTx('keep');
      final tx2 = _makeTx('drop');
      NetWatchCore.instance.addTransaction(tx);
      NetWatchCore.instance.addTransaction(tx2);
      expect(NetWatch.transactions.length, 2);
      NetWatchCore.instance.removeTransaction('drop');
      expect(NetWatch.transactions.length, 1);
      expect(NetWatch.transactions.first.id, 'keep');
    });

    test('resetUnseen drops the unseen badge counter to 0', () {
      _addDummyTx();
      _addDummyTx();
      expect(NetWatchCore.instance.unseenCount.value, greaterThan(0));
      NetWatchCore.instance.resetUnseen();
      expect(NetWatchCore.instance.unseenCount.value, 0);
    });

    test('setMasking toggles maskingEnabled', () {
      NetWatchCore.instance.setMasking(false);
      expect(NetWatchCore.instance.maskingEnabled.value, false);
      NetWatchCore.instance.setMasking(true);
      expect(NetWatchCore.instance.maskingEnabled.value, true);
    });

    test('setNotifications toggles notificationsEnabled', () {
      NetWatchCore.instance.setNotifications(false);
      expect(NetWatchCore.instance.notificationsEnabled.value, false);
      NetWatchCore.instance.setNotifications(true);
      expect(NetWatchCore.instance.notificationsEnabled.value, true);
    });

    test('clearReplayers empties registered replayers', () {
      NetWatchCore.instance.registerReplayer(NWCustomReplayer(
        canHandle: (_) => true,
        replay: (_) async {},
      ));
      expect(NetWatchCore.instance.hasReplayer, true);
      NetWatchCore.instance.clearReplayers();
      expect(NetWatchCore.instance.hasReplayer, false);
    });

    test('canReplay returns false when no replayer matches', () {
      expect(
        NetWatchCore.instance.canReplay(_makeTx('x')),
        false,
      );
    });
  });

  group('NWMemoryStorage', () {
    test('evicts oldest when over capacity', () {
      final storage = NWMemoryStorage(maxSize: 2);
      storage.add(_makeTx('a'));
      storage.add(_makeTx('b'));
      storage.add(_makeTx('c'));
      expect(storage.count, 2);
      // Newest (most recently added) is at the front; 'a' should be evicted.
      final ids = storage.getAll().map((t) => t.id).toSet();
      expect(ids, {'b', 'c'});
    });

    test('getById returns null for missing ids', () {
      final storage = NWMemoryStorage(maxSize: 5);
      expect(storage.getById('missing'), null);
    });

    test('update replaces transaction with response in place', () {
      final storage = NWMemoryStorage(maxSize: 5);
      storage.add(_makeTx('x'));
      storage.update(
        'x',
        const NWSuccessResponse(
          statusCode: 200,
          body: 'ok',
          headers: {},
          duration: Duration(milliseconds: 1),
          contentLength: null,
        ),
      );
      expect(storage.getById('x')?.statusCode, 200);
    });

    test('remove deletes by id', () {
      final storage = NWMemoryStorage(maxSize: 5);
      storage.add(_makeTx('x'));
      storage.remove('x');
      expect(storage.count, 0);
    });
  });

  group('NWHarExporter edge cases', () {
    const masker = NWMasker(
      sensitiveHeaders: NetWatchConfig.defaultSensitiveHeaders,
      sensitiveBodyFields: NetWatchConfig.defaultSensitiveBodyFields,
      sensitiveQueryParams: NetWatchConfig.defaultSensitiveQueryParams,
    );
    const exporter = NWHarExporter(masker: masker);

    test('renders pending entry when response is null', () {
      final out = exporter.exportSingle(_makeTx('p'), masked: false);
      final entry = (jsonDecode(out)['log']['entries'] as List).first as Map;
      expect((entry['response'] as Map)['statusText'], 'Pending');
    });

    test('renders status text for common codes', () {
      for (final code in [
        200,
        201,
        204,
        301,
        302,
        404,
        429,
        500,
        503,
      ]) {
        final tx = _makeTxWithResponse(code);
        final out = exporter.exportSingle(tx, masked: false);
        final entry = (jsonDecode(out)['log']['entries'] as List).first as Map;
        expect((entry['response'] as Map)['statusText'], isA<String>());
      }
    });

    test('encodes redirect location', () {
      final req = NWGetRequest(
        id: 'r',
        url: Uri.parse('https://example.com/'),
        headers: const {},
        timestamp: DateTime(2024),
      );
      final tx = NWTransaction(
        id: 'r',
        request: req,
        response: const NWRedirectResponse(
          statusCode: 302,
          location: '/new',
          headers: {},
          duration: Duration(milliseconds: 10),
          contentLength: null,
        ),
        status: const NWStatusSuccess(
          statusCode: 302,
          duration: Duration(milliseconds: 10),
        ),
        security: NWSecurityAnalysis.analyze(req),
        createdAt: DateTime(2024),
      );
      final out = exporter.exportSingle(tx, masked: false);
      final entry = (jsonDecode(out)['log']['entries'] as List).first as Map;
      expect((entry['response'] as Map)['redirectURL'], '/new');
    });

    test('encodes network error response body', () {
      final req = NWGetRequest(
        id: 'n',
        url: Uri.parse('https://example.com/'),
        headers: const {},
        timestamp: DateTime(2024),
      );
      final tx = NWTransaction(
        id: 'n',
        request: req,
        response: const NWNetworkErrorResponse(
          errorMessage: 'no route',
          originalError: null,
        ),
        status: const NWStatusNetworkError(message: 'no route'),
        security: NWSecurityAnalysis.analyze(req),
        createdAt: DateTime(2024),
      );
      final out = exporter.exportSingle(tx, masked: false);
      expect(out, contains('Network error: no route'));
    });
  });

  group('NWGraphQL edge cases', () {
    test('extracts variables', () {
      final body = {
        'query': '...',
        'variables': {'id': '1'}
      };
      expect(NWGraphQL.variables(body), {'id': '1'});
    });

    test('returns null variables when absent or non-map', () {
      expect(NWGraphQL.variables({'query': '...'}), null);
      expect(NWGraphQL.variables({'query': '...', 'variables': 'wrong'}), null);
    });

    test('query() returns the raw GraphQL string', () {
      expect(NWGraphQL.query({'query': 'query Foo { x }'}), 'query Foo { x }');
      expect(NWGraphQL.query({'no_query': true}), null);
    });

    test('responseData and responseErrors handle missing fields', () {
      expect(NWGraphQL.responseData({'errors': []}), null);
      expect(NWGraphQL.responseErrors({'data': {}}), null);
    });

    test('detects shorthand "{" query as a query operation', () {
      expect(
        NWGraphQL.operationType({'query': '{ user { id } }'}),
        'query',
      );
    });
  });
}

NWTransaction _makeTx(String id) {
  final req = NWGetRequest(
    id: id,
    url: Uri.parse('https://example.com/$id'),
    headers: const {},
    timestamp: DateTime(2024),
  );
  return NWTransaction(
    id: id,
    request: req,
    response: null,
    status: const NWStatusPending(),
    security: NWSecurityAnalysis.analyze(req),
    createdAt: DateTime(2024),
  );
}

NWTransaction _makeTxWithResponse(int code) {
  final req = NWGetRequest(
    id: '$code',
    url: Uri.parse('https://example.com/'),
    headers: const {},
    timestamp: DateTime(2024),
  );
  final response = code >= 500
      ? NWServerErrorResponse(
          statusCode: code,
          body: null,
          headers: const {},
          duration: const Duration(milliseconds: 10),
          contentLength: null,
        )
      : code >= 400
          ? NWClientErrorResponse(
              statusCode: code,
              body: null,
              headers: const {},
              duration: const Duration(milliseconds: 10),
              contentLength: null,
            )
          : code >= 300
              ? NWRedirectResponse(
                  statusCode: code,
                  location: '/x',
                  headers: const {},
                  duration: const Duration(milliseconds: 10),
                  contentLength: null,
                )
              : NWSuccessResponse(
                  statusCode: code,
                  body: 'ok',
                  headers: const {},
                  duration: const Duration(milliseconds: 10),
                  contentLength: null,
                );
  return NWTransaction(
    id: '$code',
    request: req,
    response: response,
    status: const NWStatusSuccess(
      statusCode: 200,
      duration: Duration(milliseconds: 10),
    ),
    security: NWSecurityAnalysis.analyze(req),
    createdAt: DateTime(2024),
  );
}

void _addDummyTx() {
  NetWatchCore.instance.addTransaction(
    _makeTx(DateTime.now().microsecondsSinceEpoch.toString()),
  );
}
