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

  test('Captures GET request and 200 response', () async {
    final client = NWHttpClient(
      MockClient((req) async => http.Response('{"ok":true}', 200, headers: {
            'content-type': 'application/json',
          })),
    );
    final response = await client.get(Uri.parse('https://example.com/x'));
    expect(response.statusCode, 200);
    expect(NetWatch.transactions.length, 1);
    final tx = NetWatch.transactions.first;
    expect(tx.request, isA<NWGetRequest>());
    expect(tx.response, isA<NWSuccessResponse>());
  });

  test('Captures POST with JSON body', () async {
    final client = NWHttpClient(
      MockClient((req) async {
        return http.Response('{}', 201,
            headers: {'content-type': 'application/json'});
      }),
    );
    await client.post(
      Uri.parse('https://example.com/users'),
      headers: {'content-type': 'application/json'},
      body: '{"name":"alice"}',
    );
    final tx = NetWatch.transactions.first;
    expect(tx.request, isA<NWPostRequest>());
    expect(tx.statusCode, 201);
  });

  test('Captures 404 as NWClientErrorResponse', () async {
    final client = NWHttpClient(
      MockClient((req) async => http.Response('not found', 404)),
    );
    await client.get(Uri.parse('https://example.com/missing'));
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWClientErrorResponse>());
  });

  test('Captures 500 as NWServerErrorResponse', () async {
    final client = NWHttpClient(
      MockClient((req) async => http.Response('boom', 500)),
    );
    await client.get(Uri.parse('https://example.com/oops'));
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWServerErrorResponse>());
  });

  test('Captures 302 as NWRedirectResponse', () async {
    final client = NWHttpClient(
      MockClient((req) async => http.Response('', 302, headers: {
            'location': '/elsewhere',
          })),
    );
    await client.get(Uri.parse('https://example.com/old'));
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWRedirectResponse>());
  });

  test('Captures thrown error as NWNetworkErrorResponse', () async {
    final client = NWHttpClient(
      MockClient((req) async => throw Exception('connection refused')),
    );
    try {
      await client.get(Uri.parse('https://example.com/'));
    } catch (_) {}
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWNetworkErrorResponse>());
  });

  test('Decodes JSON response body when content-type is JSON', () async {
    final client = NWHttpClient(
      MockClient((req) async => http.Response('{"value":42}', 200, headers: {
            'content-type': 'application/json',
          })),
    );
    await client.get(Uri.parse('https://example.com/'));
    final tx = NetWatch.transactions.first;
    final r = tx.response as NWSuccessResponse;
    expect(r.body, {'value': 42});
  });

  test('Captures every HTTP method', () async {
    final captured = <String>[];
    final client = NWHttpClient(
      MockClient((req) async {
        captured.add(req.method);
        return http.Response('{}', 200);
      }),
    );
    await client.get(Uri.parse('https://example.com/x'));
    await client.head(Uri.parse('https://example.com/x'));
    await client.post(Uri.parse('https://example.com/x'), body: 'x');
    await client.put(Uri.parse('https://example.com/x'), body: 'x');
    await client.patch(Uri.parse('https://example.com/x'), body: 'x');
    await client.delete(Uri.parse('https://example.com/x'));
    expect(captured, ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE']);
  });

  test('Captures multipart/form-data request', () async {
    final client = NWHttpClient(
      MockClient((req) async => http.Response('{}', 200)),
    );
    final multipart = http.MultipartRequest(
      'POST',
      Uri.parse('https://example.com/upload'),
    );
    multipart.fields['name'] = 'alice';
    multipart.files.add(http.MultipartFile.fromBytes(
      'avatar',
      [1, 2, 3, 4],
      filename: 'pic.png',
    ));
    await client.send(multipart);
    final tx = NetWatch.transactions.first;
    expect(tx.request, isA<NWMultipartRequest>());
    final mp = tx.request as NWMultipartRequest;
    expect(mp.fields['name'], 'alice');
    expect(mp.files.length, 1);
    expect(mp.files.first.fieldName, 'avatar');
  });

  test('close() delegates to inner client', () {
    var innerClosed = false;
    final inner = _ClosableMockClient(() => innerClosed = true);
    final client = NWHttpClient(inner);
    client.close();
    expect(innerClosed, true);
  });

  test('Passes through without capture when disabled', () async {
    NetWatch.initialize(config: const NetWatchConfig(enabled: false));

    final client = NWHttpClient(
      MockClient((req) async => http.Response('{"ok":true}', 200)),
    );

    final response = await client.get(Uri.parse('https://example.com/x'));

    expect(response.statusCode, 200);
    expect(NetWatch.transactions, isEmpty);
  });
}

class _ClosableMockClient extends http.BaseClient {
  final void Function() onClose;
  _ClosableMockClient(this.onClose);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      const Stream<List<int>>.empty(),
      200,
    );
  }

  @override
  void close() {
    onClose();
    super.close();
  }
}
