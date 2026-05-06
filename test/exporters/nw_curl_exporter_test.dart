import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const masker = NWMasker(
    sensitiveHeaders: NetWatchConfig.defaultSensitiveHeaders,
    sensitiveBodyFields: NetWatchConfig.defaultSensitiveBodyFields,
    sensitiveQueryParams: NetWatchConfig.defaultSensitiveQueryParams,
  );
  const exporter = NWCurlExporter(masker: masker);

  NWTransaction makeTx(NWRequest request) => NWTransaction(
        id: '1',
        request: request,
        response: null,
        status: const NWStatusPending(),
        security: NWSecurityAnalysis.analyze(request),
        createdAt: DateTime(2024, 1, 1),
      );

  test('Generates valid GET cURL', () {
    final tx = makeTx(NWGetRequest(
      id: '1',
      url: Uri.parse('https://api.example.com/users'),
      headers: const {'Accept': 'application/json'},
      timestamp: DateTime(2024, 1, 1),
    ));
    final out = exporter.export(tx, masked: false);
    expect(out, contains("curl -X GET 'https://api.example.com/users'"));
    expect(out, contains("-H 'Accept: application/json'"));
  });

  test('Generates valid POST with JSON body', () {
    final tx = makeTx(NWPostRequest(
      id: '1',
      url: Uri.parse('https://api.example.com/users'),
      headers: const {'Content-Type': 'application/json'},
      body: const {'name': 'John'},
      timestamp: DateTime(2024, 1, 1),
    ));
    final out = exporter.export(tx, masked: false);
    expect(out, contains('curl -X POST'));
    expect(out, contains('--data-raw'));
    expect(out, contains('"name"'));
    expect(out, contains('"John"'));
  });

  test('Generates valid PUT cURL', () {
    final tx = makeTx(NWPutRequest(
      id: '1',
      url: Uri.parse('https://api.example.com/users/1'),
      headers: const {},
      body: const {'name': 'X'},
      timestamp: DateTime(2024, 1, 1),
    ));
    expect(exporter.export(tx, masked: false), contains('curl -X PUT'));
  });

  test('Generates valid DELETE cURL', () {
    final tx = makeTx(NWDeleteRequest(
      id: '1',
      url: Uri.parse('https://api.example.com/users/1'),
      headers: const {},
      body: null,
      timestamp: DateTime(2024, 1, 1),
    ));
    expect(exporter.export(tx, masked: false), contains('curl -X DELETE'));
  });

  test('Masks values when masked=true', () {
    final tx = makeTx(NWPostRequest(
      id: '1',
      url: Uri.parse('https://api.example.com/login'),
      headers: const {'Authorization': 'Bearer xxx'},
      body: const {'password': 'secret'},
      timestamp: DateTime(2024, 1, 1),
    ));
    final out = exporter.export(tx, masked: true);
    expect(out, contains('Authorization: $nwMaskedValue'));
    expect(out, contains(nwMaskedValue));
    expect(out, isNot(contains('Bearer xxx')));
    expect(out, isNot(contains('secret')));
  });

  test('Shows raw values when masked=false', () {
    final tx = makeTx(NWPostRequest(
      id: '1',
      url: Uri.parse('https://api.example.com/login'),
      headers: const {'Authorization': 'Bearer xxx'},
      body: const {'password': 'secret'},
      timestamp: DateTime(2024, 1, 1),
    ));
    final out = exporter.export(tx, masked: false);
    expect(out, contains('Bearer xxx'));
  });

  test('Handles empty body', () {
    final tx = makeTx(NWGetRequest(
      id: '1',
      url: Uri.parse('https://api.example.com'),
      headers: const {},
      timestamp: DateTime(2024, 1, 1),
    ));
    final out = exporter.export(tx, masked: false);
    expect(out, isNot(contains('--data-raw')));
  });

  test('Handles multipart request', () {
    final tx = makeTx(NWMultipartRequest(
      id: '1',
      url: Uri.parse('https://api.example.com/upload'),
      headers: const {},
      timestamp: DateTime(2024, 1, 1),
      files: const [
        NWMultipartFile(
          fieldName: 'file',
          fileName: 'photo.jpg',
          sizeBytes: 1024,
          contentType: 'image/jpeg',
        ),
      ],
    ));
    final out = exporter.export(tx, masked: false);
    expect(out, contains("-F 'file=@/path/to/photo.jpg'"));
  });
}
