import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

NWGetRequest _req(String url) => NWGetRequest(
      id: '1',
      url: Uri.parse(url),
      headers: const {'X-Custom': 'v'},
      timestamp: DateTime(2024),
    );

void main() {
  group('NWDioReplayer', () {
    test('canHandle defaults to true', () {
      final dio = Dio();
      final replayer = NWDioReplayer(dio);
      expect(replayer.canHandle(_req('https://example.com')), true);
    });

    test('canHandle uses matcher when provided', () {
      final dio = Dio();
      final replayer = NWDioReplayer(
        dio,
        matcher: (r) => r.url.host == 'allow.com',
      );
      expect(replayer.canHandle(_req('https://allow.com')), true);
      expect(replayer.canHandle(_req('https://block.com')), false);
    });

    test('replay re-fires through the dio adapter', () async {
      final dio = Dio();
      var fired = false;
      dio.httpClientAdapter = _RecordingAdapter(() => fired = true);
      final replayer = NWDioReplayer(dio);
      await replayer.replay(_req('https://example.com/x'));
      expect(fired, true);
    });
  });

  group('NWHttpClientReplayer', () {
    test('canHandle uses matcher when provided', () {
      final client = MockClient((_) async => http.Response('ok', 200));
      final replayer = NWHttpClientReplayer(
        client,
        matcher: (r) => r.method == 'GET',
      );
      expect(replayer.canHandle(_req('https://example.com')), true);
      expect(
        replayer.canHandle(NWPostRequest(
          id: '1',
          url: Uri.parse('https://example.com'),
          headers: const {},
          body: null,
          timestamp: DateTime(2024),
        )),
        false,
      );
    });

    test('replay GET fires through client', () async {
      Uri? captured;
      final client = MockClient((req) async {
        captured = req.url;
        return http.Response('ok', 200);
      });
      await NWHttpClientReplayer(client).replay(_req('https://example.com/y'));
      expect(captured.toString(), 'https://example.com/y');
    });

    test('replay POST sends body', () async {
      String? capturedBody;
      final client = MockClient((req) async {
        capturedBody = req.body;
        return http.Response('ok', 200);
      });
      await NWHttpClientReplayer(client).replay(NWPostRequest(
        id: '1',
        url: Uri.parse('https://example.com/z'),
        headers: const {},
        body: 'payload',
        timestamp: DateTime(2024),
      ));
      expect(capturedBody, 'payload');
    });

    test('replay handles each HTTP method', () async {
      final methods = <String>[];
      final client = MockClient((req) async {
        methods.add(req.method);
        return http.Response('ok', 200);
      });
      final replayer = NWHttpClientReplayer(client);

      await replayer.replay(_req('https://example.com/'));
      await replayer.replay(NWHeadRequest(
        id: '1',
        url: Uri.parse('https://example.com/'),
        headers: const {},
        timestamp: DateTime(2024),
      ));
      await replayer.replay(NWPostRequest(
        id: '1',
        url: Uri.parse('https://example.com/'),
        headers: const {},
        body: '{}',
        timestamp: DateTime(2024),
      ));
      await replayer.replay(NWPutRequest(
        id: '1',
        url: Uri.parse('https://example.com/'),
        headers: const {},
        body: '{}',
        timestamp: DateTime(2024),
      ));
      await replayer.replay(NWPatchRequest(
        id: '1',
        url: Uri.parse('https://example.com/'),
        headers: const {},
        body: '{}',
        timestamp: DateTime(2024),
      ));
      await replayer.replay(NWDeleteRequest(
        id: '1',
        url: Uri.parse('https://example.com/'),
        headers: const {},
        body: null,
        timestamp: DateTime(2024),
      ));
      expect(methods, ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE']);
    });

    test('encodes a Map<String,String> body as form fields', () async {
      late final dynamic captured;
      final client = MockClient((req) async {
        captured = req.body;
        return http.Response('ok', 200);
      });
      await NWHttpClientReplayer(client).replay(NWPostRequest(
        id: '1',
        url: Uri.parse('https://example.com/'),
        headers: const {},
        body: const {'k': 'v'},
        timestamp: DateTime(2024),
      ));
      expect(captured, contains('k=v'));
    });
  });

  group('NWCustomReplayer', () {
    test('delegates canHandle and replay to callbacks', () async {
      var canHandleCalls = 0;
      var replayCalls = 0;
      final replayer = NWCustomReplayer(
        canHandle: (r) {
          canHandleCalls++;
          return r.url.host == 'allow.com';
        },
        replay: (r) async {
          replayCalls++;
        },
      );
      expect(replayer.canHandle(_req('https://allow.com')), true);
      expect(replayer.canHandle(_req('https://block.com')), false);
      await replayer.replay(_req('https://allow.com'));
      expect(canHandleCalls, 2);
      expect(replayCalls, 1);
    });
  });

  group('NetWatchCore replay wiring', () {
    setUp(() {
      NetWatch.initialize(config: const NetWatchConfig());
      NetWatchCore.instance.clearReplayers();
    });

    test('hasReplayer reflects registered replayers', () {
      expect(NetWatch.hasReplayer, false);
      NetWatch.registerReplayer(NWCustomReplayer(
        canHandle: (_) => true,
        replay: (_) async {},
      ));
      expect(NetWatch.hasReplayer, true);
    });

    test('replay routes to a matching replayer', () async {
      var fired = false;
      NetWatch.registerReplayer(NWCustomReplayer(
        canHandle: (r) => r.url.host == 'a.com',
        replay: (r) async {
          fired = true;
        },
      ));
      final tx = NWTransaction(
        id: '1',
        request: _req('https://a.com'),
        response: null,
        status: const NWStatusPending(),
        security: NWSecurityAnalysis.analyze(_req('https://a.com')),
        createdAt: DateTime(2024),
      );
      await NetWatch.replay(tx);
      expect(fired, true);
    });

    test('replay throws StateError when no replayer matches', () async {
      NetWatch.registerReplayer(NWCustomReplayer(
        canHandle: (_) => false,
        replay: (_) async {},
      ));
      final tx = NWTransaction(
        id: '1',
        request: _req('https://example.com'),
        response: null,
        status: const NWStatusPending(),
        security: NWSecurityAnalysis.analyze(_req('https://example.com')),
        createdAt: DateTime(2024),
      );
      expect(NetWatch.replay(tx), throwsStateError);
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  final void Function() onFetch;
  _RecordingAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onFetch();
    return ResponseBody.fromString('{}', 200, headers: {
      'content-type': ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}
