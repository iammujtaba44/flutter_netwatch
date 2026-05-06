import 'dart:convert';

import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const masker = NWMasker(
    sensitiveHeaders: NetWatchConfig.defaultSensitiveHeaders,
    sensitiveBodyFields: NetWatchConfig.defaultSensitiveBodyFields,
    sensitiveQueryParams: NetWatchConfig.defaultSensitiveQueryParams,
  );

  group('NWMasker headers', () {
    test('Masks Authorization header value', () {
      final result = masker.maskHeaders({'Authorization': 'Bearer xxx'});
      expect(result['Authorization'], nwMaskedValue);
    });

    test('Case-insensitive header matching', () {
      final result = masker.maskHeaders({'AUTHORIZATION': 'Bearer xxx'});
      expect(result['AUTHORIZATION'], nwMaskedValue);
    });

    test('Does not mask non-sensitive headers', () {
      final result = masker.maskHeaders({
        'X-Trace-Id': 'abc123',
        'Accept': 'application/json',
      });
      expect(result['X-Trace-Id'], 'abc123');
      expect(result['Accept'], 'application/json');
    });

    test('Masks Cookie header', () {
      final result = masker.maskHeaders({'Cookie': 'session=secret'});
      expect(result['Cookie'], nwMaskedValue);
    });
  });

  group('NWMasker body', () {
    test('Masks nested JSON body field', () {
      final body = {
        'username': 'john',
        'password': 'secret',
      };
      final result = masker.maskBody(body) as Map<String, dynamic>;
      expect(result['password'], nwMaskedValue);
      expect(result['username'], 'john');
    });

    test('Masks deeply nested JSON field', () {
      final body = {
        'user': {
          'profile': {
            'name': 'John',
            'token': 'jwt-here',
          },
        },
      };
      final result = masker.maskBody(body) as Map<String, dynamic>;
      final user = result['user'] as Map<String, dynamic>;
      final profile = user['profile'] as Map<String, dynamic>;
      expect(profile['token'], nwMaskedValue);
      expect(profile['name'], 'John');
    });

    test('Handles null body', () {
      expect(masker.maskBody(null), isNull);
    });

    test('Handles list body', () {
      final body = [
        {'token': 'a'},
        {'token': 'b'},
      ];
      final result = masker.maskBody(body) as List;
      expect((result[0] as Map)['token'], nwMaskedValue);
      expect((result[1] as Map)['token'], nwMaskedValue);
    });

    test('Handles JSON string body', () {
      const raw = '{"password":"hi","name":"alex"}';
      final result = masker.maskBody(raw) as String;
      final decoded = jsonDecode(result) as Map<String, dynamic>;
      expect(decoded['password'], nwMaskedValue);
      expect(decoded['name'], 'alex');
    });

    test('Handles non-JSON string body unchanged', () {
      const raw = 'plain text body, not JSON';
      expect(masker.maskBody(raw), raw);
    });

    test('Case-insensitive field matching', () {
      final result = masker.maskBody({'PASSWORD': 'x'}) as Map<String, dynamic>;
      expect(result['PASSWORD'], nwMaskedValue);
    });
  });

  group('NWMasker URL', () {
    test('Masks URL query param', () {
      final url =
          Uri.parse('https://api.example.com/path?token=secret&q=hello');
      final result = masker.maskUrl(url);
      expect(result.queryParameters['token'], nwMaskedValue);
      expect(result.queryParameters['q'], 'hello');
    });

    test('Returns same URL when no query params', () {
      final url = Uri.parse('https://api.example.com/path');
      expect(masker.maskUrl(url), url);
    });
  });
}
