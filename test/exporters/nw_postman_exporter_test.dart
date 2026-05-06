import 'dart:convert';

import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const masker = NWMasker(
    sensitiveHeaders: NetWatchConfig.defaultSensitiveHeaders,
    sensitiveBodyFields: NetWatchConfig.defaultSensitiveBodyFields,
    sensitiveQueryParams: NetWatchConfig.defaultSensitiveQueryParams,
  );
  const exporter = NWPostmanExporter(masker: masker);

  NWTransaction makeTx({
    NWRequest? request,
    NWResponse? response,
  }) {
    final req = request ??
        NWGetRequest(
          id: '1',
          url: Uri.parse('https://api.example.com/users?token=abc'),
          headers: const {'Accept': 'application/json'},
          timestamp: DateTime(2024, 1, 1),
        );
    return NWTransaction(
      id: '1',
      request: req,
      response: response,
      status: response == null
          ? const NWStatusPending()
          : const NWStatusSuccess(
              statusCode: 200,
              duration: Duration(milliseconds: 100),
            ),
      security: NWSecurityAnalysis.analyze(req),
      createdAt: DateTime(2024, 1, 1),
    );
  }

  test('Generates valid Postman Collection v2.1 JSON', () {
    final json = exporter.exportCollection([makeTx()], masked: false);
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    expect(parsed['info'], isA<Map>());
    expect((parsed['info'] as Map)['schema'],
        contains('schema.getpostman.com/json/collection/v2.1.0'));
    expect(parsed['item'], isA<List>());
  });

  test('Single transaction export', () {
    final json = exporter.exportSingle(makeTx(), masked: false);
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    expect(parsed['name'], contains('GET'));
    expect((parsed['request'] as Map)['method'], 'GET');
  });

  test('Multiple transaction export', () {
    final json = exporter.exportCollection(
      [makeTx(), makeTx(), makeTx()],
      masked: false,
    );
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    expect((parsed['item'] as List).length, 3);
  });

  test('Includes response in export', () {
    final tx = makeTx(
      response: const NWSuccessResponse(
        statusCode: 200,
        body: {'ok': true},
        headers: {'content-type': 'application/json'},
        duration: Duration(milliseconds: 50),
        contentLength: null,
      ),
    );
    final json = exporter.exportSingle(tx, masked: false);
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    expect(parsed['response'], isA<List>());
    expect(((parsed['response'] as List).first as Map)['code'], 200);
  });

  test('Applies masking correctly', () {
    final tx = makeTx(
      request: NWPostRequest(
        id: '1',
        url: Uri.parse('https://api.example.com/login'),
        headers: const {'Authorization': 'Bearer xxx'},
        body: const {'password': 'secret', 'username': 'john'},
        timestamp: DateTime(2024, 1, 1),
      ),
    );
    final json = exporter.exportSingle(tx, masked: true);
    expect(json, contains(nwMaskedValue));
    expect(json, isNot(contains('Bearer xxx')));
    expect(json, isNot(contains('"secret"')));
    expect(json, contains('john'));
  });

  test('Collection name configurable', () {
    final json = exporter.exportCollection(
      [makeTx()],
      collectionName: 'My Custom Collection',
      masked: false,
    );
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    expect((parsed['info'] as Map)['name'], 'My Custom Collection');
  });
}
