import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const masker = NWMasker(
    sensitiveHeaders: NetWatchConfig.defaultSensitiveHeaders,
    sensitiveBodyFields: NetWatchConfig.defaultSensitiveBodyFields,
    sensitiveQueryParams: NetWatchConfig.defaultSensitiveQueryParams,
  );
  const exporter = NWShareExporter(masker: masker);

  NWTransaction makeTx({
    NWRequest? request,
    NWResponse? response,
  }) {
    final req = request ??
        NWPostRequest(
          id: '1',
          url: Uri.parse('https://api.example.com/login'),
          headers: const {
            'Authorization': 'Bearer xxx',
            'Content-Type': 'application/json',
          },
          body: const {'username': 'alice', 'password': 'secret'},
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

  test('Includes method, URL, status, and timestamp', () {
    final tx = makeTx(
      response: const NWSuccessResponse(
        statusCode: 200,
        body: {'ok': true},
        headers: {'content-type': 'application/json'},
        duration: Duration(milliseconds: 100),
        contentLength: null,
      ),
    );
    final out = exporter.exportAsText(tx, masked: false);
    expect(out, contains('=== NetWatch Export ==='));
    expect(out, contains('POST'));
    expect(out, contains('api.example.com/login'));
    expect(out, contains('Status: 200'));
    expect(out, contains('Duration: 100ms'));
  });

  test('Renders request headers', () {
    final out = exporter.exportAsText(makeTx(), masked: false);
    expect(out, contains('--- REQUEST HEADERS ---'));
    expect(out, contains('Authorization: Bearer xxx'));
  });

  test('Masks sensitive headers and body fields when masked=true', () {
    final out = exporter.exportAsText(makeTx(), masked: true);
    expect(out, contains(nwMaskedValue));
    expect(out, isNot(contains('Bearer xxx')));
    expect(out, isNot(contains('"password": "secret"')));
  });

  test('Renders response section when present', () {
    final tx = makeTx(
      response: const NWSuccessResponse(
        statusCode: 200,
        body: {'ok': true},
        headers: {'x-custom': 'v'},
        duration: Duration(milliseconds: 50),
        contentLength: null,
      ),
    );
    final out = exporter.exportAsText(tx, masked: false);
    expect(out, contains('--- RESPONSE HEADERS ---'));
    expect(out, contains('x-custom: v'));
    expect(out, contains('--- RESPONSE BODY ---'));
  });

  test('Handles network error response', () {
    final tx = makeTx(
      response: const NWNetworkErrorResponse(
        errorMessage: 'connection refused',
        originalError: null,
      ),
    );
    final out = exporter.exportAsText(tx, masked: false);
    expect(out, contains('Network error: connection refused'));
  });

  test('Handles redirect response', () {
    final tx = makeTx(
      response: const NWRedirectResponse(
        statusCode: 302,
        location: '/elsewhere',
        headers: {},
        duration: Duration(milliseconds: 5),
        contentLength: null,
      ),
    );
    final out = exporter.exportAsText(tx, masked: false);
    expect(out, contains('Redirect → /elsewhere'));
  });

  test('Handles GET with no body and no response', () {
    final tx = makeTx(
      request: NWGetRequest(
        id: '2',
        url: Uri.parse('https://api.example.com/x'),
        headers: const {},
        timestamp: DateTime(2024, 1, 1),
      ),
    );
    final out = exporter.exportAsText(tx, masked: false);
    expect(out, contains('--- REQUEST HEADERS ---'));
    expect(out, contains('(none)'));
    expect(out, isNot(contains('--- REQUEST BODY ---')));
    expect(out, isNot(contains('--- RESPONSE HEADERS ---')));
  });
}
