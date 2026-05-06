import 'package:chopper/chopper.dart';
import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    NetWatch.initialize(
      config: const NetWatchConfig(performanceBudgetMs: 1000),
    );
    NetWatchCore.instance.clearAll();
  });

  ChopperClient buildChopper(http.Client httpClient) {
    return ChopperClient(
      baseUrl: Uri.parse('https://api.example.com'),
      client: httpClient,
      interceptors: [NWChopperInterceptor()],
    );
  }

  test('Captures GET request', () async {
    final chopper = buildChopper(
      MockClient((req) async => http.Response('{}', 200, headers: {
            'content-type': 'application/json',
          })),
    );
    final request = Request('GET', Uri.parse('/users'), chopper.baseUrl);
    await chopper.send<dynamic, dynamic>(request);
    expect(NetWatch.transactions.length, 1);
    expect(NetWatch.transactions.first.request, isA<NWGetRequest>());
  });

  test('Captures POST with body and parses 201', () async {
    final chopper = buildChopper(
      MockClient((req) async => http.Response(
            '{"id":1}',
            201,
            headers: {'content-type': 'application/json'},
          )),
    );
    final request = Request(
      'POST',
      Uri.parse('/users'),
      chopper.baseUrl,
      body: '{"name":"alice"}',
      headers: const {'content-type': 'application/json'},
    );
    await chopper.send<dynamic, dynamic>(request);
    final tx = NetWatch.transactions.first;
    expect(tx.request, isA<NWPostRequest>());
    expect(tx.statusCode, 201);
    expect(tx.response, isA<NWSuccessResponse>());
  });

  test('Captures 404 as NWClientErrorResponse', () async {
    final chopper = buildChopper(
      MockClient((req) async => http.Response('not found', 404)),
    );
    try {
      await chopper.send<dynamic, dynamic>(
        Request('GET', Uri.parse('/missing'), chopper.baseUrl),
      );
    } catch (_) {}
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWClientErrorResponse>());
  });

  test('Captures 500 as NWServerErrorResponse', () async {
    final chopper = buildChopper(
      MockClient((req) async => http.Response('boom', 500)),
    );
    try {
      await chopper.send<dynamic, dynamic>(
        Request('GET', Uri.parse('/oops'), chopper.baseUrl),
      );
    } catch (_) {}
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWServerErrorResponse>());
  });

  test('Captures 301 as NWRedirectResponse', () async {
    final chopper = buildChopper(
      MockClient((req) async => http.Response('', 301, headers: {
            'location': '/new',
          })),
    );
    await chopper.send<dynamic, dynamic>(
      Request('GET', Uri.parse('/old'), chopper.baseUrl),
    );
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWRedirectResponse>());
  });

  test('Captures thrown error as NWNetworkErrorResponse', () async {
    final chopper = buildChopper(
      MockClient((req) async => throw Exception('boom')),
    );
    try {
      await chopper.send<dynamic, dynamic>(
        Request('GET', Uri.parse('/'), chopper.baseUrl),
      );
    } catch (_) {}
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWNetworkErrorResponse>());
  });

  test('Decodes JSON request body when content-type is JSON', () async {
    final chopper = buildChopper(
      MockClient((req) async => http.Response('{}', 200)),
    );
    await chopper.send<dynamic, dynamic>(
      Request(
        'POST',
        Uri.parse('/x'),
        chopper.baseUrl,
        body: '{"k":"v"}',
        headers: const {'content-type': 'application/json'},
      ),
    );
    final tx = NetWatch.transactions.first;
    expect(tx.request.body, {'k': 'v'});
  });

  test('Captures every HTTP method', () async {
    final chopper = buildChopper(
      MockClient((req) async => http.Response('{}', 200)),
    );
    for (final method in ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']) {
      await chopper.send<dynamic, dynamic>(
        Request(method, Uri.parse('/x'), chopper.baseUrl),
      );
    }
    final captured = NetWatch.transactions.map((t) => t.request.method).toList()
      ..sort();
    expect(captured, ['DELETE', 'GET', 'HEAD', 'PATCH', 'POST', 'PUT']);
  });
}
