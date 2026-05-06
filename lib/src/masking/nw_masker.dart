import 'dart:convert';

const String nwMaskedValue = '[MASKED]';

/// Pure, stateless masker — replaces values for sensitive header keys, body
/// fields, and URL query params with [nwMaskedValue]. Matching is
/// case-insensitive. Safe to share across threads.
class NWMasker {
  final List<String> sensitiveHeaders;
  final List<String> sensitiveBodyFields;
  final List<String> sensitiveQueryParams;

  const NWMasker({
    required this.sensitiveHeaders,
    required this.sensitiveBodyFields,
    required this.sensitiveQueryParams,
  });

  Map<String, String> maskHeaders(Map<String, String> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _isSensitiveHeader(entry.key) ? nwMaskedValue : entry.value,
    };
  }

  Object? maskBody(Object? body) {
    if (body == null) return null;
    if (body is Map) {
      return _maskMap(Map<String, dynamic>.from(body));
    }
    if (body is List) {
      return body.map(maskBody).toList();
    }
    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return jsonEncode(_maskMap(decoded));
        }
        if (decoded is List) {
          return jsonEncode(decoded.map(maskBody).toList());
        }
      } catch (_) {}
      return body;
    }
    return body;
  }

  Uri maskUrl(Uri url) {
    if (url.queryParameters.isEmpty) return url;
    final masked = <String, String>{
      for (final entry in url.queryParameters.entries)
        entry.key:
            _isSensitiveQueryParam(entry.key) ? nwMaskedValue : entry.value,
    };
    return url.replace(queryParameters: masked);
  }

  Map<String, dynamic> _maskMap(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (_isSensitiveField(entry.key)) {
        result[entry.key] = nwMaskedValue;
        continue;
      }
      final value = entry.value;
      if (value is Map || value is List) {
        result[entry.key] = maskBody(value);
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }

  bool _isSensitiveHeader(String key) {
    final lower = key.toLowerCase();
    return sensitiveHeaders.any((h) => h.toLowerCase() == lower);
  }

  bool _isSensitiveField(String key) {
    final lower = key.toLowerCase();
    return sensitiveBodyFields.any((f) => f.toLowerCase() == lower);
  }

  bool _isSensitiveQueryParam(String key) {
    final lower = key.toLowerCase();
    return sensitiveQueryParams.any((p) => p.toLowerCase() == lower);
  }
}
