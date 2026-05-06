import 'dart:convert';

import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const masker = NWMasker(
    sensitiveHeaders: NetWatchConfig.defaultSensitiveHeaders,
    sensitiveBodyFields: NetWatchConfig.defaultSensitiveBodyFields,
    sensitiveQueryParams: NetWatchConfig.defaultSensitiveQueryParams,
  );
  const exporter = NWHarExporter(masker: masker);

  NWTransaction makeTx({NWResponse? response}) {
    final req = NWGetRequest(
      id: '1',
      url: Uri.parse('https://api.example.com/users?token=abc&q=hi'),
      headers: const {
        'Accept': 'application/json',
        'Authorization': 'Bearer xxx',
      },
      timestamp: DateTime(2024, 1, 1, 12),
    );
    return NWTransaction(
      id: '1',
      request: req,
      response: response,
      status: response == null
          ? const NWStatusPending()
          : const NWStatusSuccess(
              statusCode: 200,
              duration: Duration(milliseconds: 123),
            ),
      security: NWSecurityAnalysis.analyze(req),
      createdAt: DateTime(2024, 1, 1, 12),
    );
  }

  test('Generates HAR 1.2 envelope', () {
    final out = exporter.exportAll([makeTx()], masked: false);
    final parsed = jsonDecode(out) as Map<String, dynamic>;
    final log = parsed['log'] as Map<String, dynamic>;
    expect(log['version'], '1.2');
    expect((log['creator'] as Map)['name'], 'flutter_netwatch');
    expect(log['entries'], isA<List>());
  });

  test('Encodes request method, url, headers, and query', () {
    final out = exporter.exportSingle(makeTx(), masked: false);
    final parsed = jsonDecode(out) as Map<String, dynamic>;
    final entry = (parsed['log'] as Map)['entries'][0] as Map<String, dynamic>;
    final request = entry['request'] as Map<String, dynamic>;
    expect(request['method'], 'GET');
    expect(request['url'], contains('api.example.com'));
    expect(request['headers'], isA<List>());
    expect(
        (request['headers'] as List).any((h) => h['name'] == 'Accept'), true);
    expect((request['queryString'] as List).any((q) => q['name'] == 'q'), true);
  });

  test('Encodes response status and body', () {
    final tx = makeTx(
      response: const NWSuccessResponse(
        statusCode: 200,
        body: {'ok': true},
        headers: {'content-type': 'application/json'},
        duration: Duration(milliseconds: 50),
        contentLength: null,
      ),
    );
    final out = exporter.exportSingle(tx, masked: false);
    final parsed = jsonDecode(out) as Map<String, dynamic>;
    final entry = (parsed['log'] as Map)['entries'][0] as Map<String, dynamic>;
    final response = entry['response'] as Map<String, dynamic>;
    expect(response['status'], 200);
    expect(response['statusText'], 'OK');
    expect((response['content'] as Map)['mimeType'], 'application/json');
    expect((response['content'] as Map)['text'], contains('"ok":true'));
  });

  test('Applies masking to headers and query', () {
    final out = exporter.exportSingle(makeTx(), masked: true);
    expect(out, contains(nwMaskedValue));
    expect(out, isNot(contains('Bearer xxx')));
    expect(out, isNot(contains('"value":"abc"')));
  });

  test('Multiple entries', () {
    final out = exporter.exportAll(
      [makeTx(), makeTx(), makeTx()],
      masked: false,
    );
    final parsed = jsonDecode(out) as Map<String, dynamic>;
    expect(((parsed['log'] as Map)['entries'] as List).length, 3);
  });
}
