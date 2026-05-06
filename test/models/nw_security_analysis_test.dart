import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NWGetRequest req(String url, {Map<String, String> headers = const {}}) =>
      NWGetRequest(
        id: 'x',
        url: Uri.parse(url),
        headers: headers,
        timestamp: DateTime(2024, 1, 1),
      );

  test('Flags HTTP as critical', () {
    final analysis = NWSecurityAnalysis.analyze(req('http://example.com'));
    expect(analysis.isHttps, false);
    expect(analysis.rating, NWSecurityRating.critical);
    expect(
      analysis.issues.any(
        (i) =>
            i.severity == NWSecuritySeverity.critical &&
            i.title.contains('Insecure'),
      ),
      true,
    );
  });

  test('Flags missing HSTS as warning', () {
    final analysis = NWSecurityAnalysis.analyze(req('https://example.com'));
    expect(
      analysis.issues.any((i) => i.title.contains('HSTS')),
      true,
    );
  });

  test('Flags sensitive data in URL params as critical', () {
    final analysis =
        NWSecurityAnalysis.analyze(req('https://example.com?token=abc'));
    expect(analysis.rating, NWSecurityRating.critical);
    expect(
      analysis.issues.any((i) => i.title == 'Sensitive data in URL'),
      true,
    );
  });

  test('Flags Basic auth as warning', () {
    final analysis = NWSecurityAnalysis.analyze(req(
      'https://example.com',
      headers: const {'Authorization': 'Basic YWxhZGRpbjpvcGVuc2VzYW1l'},
    ));
    expect(
      analysis.issues.any((i) => i.title == 'Basic auth detected'),
      true,
    );
  });

  test('Rates good when no issues', () {
    final analysis = NWSecurityAnalysis.analyze(req(
      'https://example.com',
      headers: const {
        'strict-transport-security': 'max-age=31536000',
        'x-content-type-options': 'nosniff',
        'content-security-policy': "default-src 'self'",
      },
    ));
    expect(analysis.rating, NWSecurityRating.good);
    expect(analysis.issues, isEmpty);
  });

  test('Rates critical when any critical issue exists', () {
    final analysis = NWSecurityAnalysis.analyze(req('http://example.com'));
    expect(analysis.rating, NWSecurityRating.critical);
  });

  test('Rates warning when only warnings exist', () {
    final analysis = NWSecurityAnalysis.analyze(req(
      'https://example.com',
      headers: const {
        'content-security-policy': "default-src 'self'",
      },
    ));
    expect(analysis.rating, NWSecurityRating.warning);
  });
}
