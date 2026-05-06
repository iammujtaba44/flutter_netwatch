import 'dart:convert';

import '../masking/nw_masker.dart';
import '../models/nw_request.dart';
import '../models/nw_response.dart';
import '../models/nw_transaction.dart';

/// Exports transactions as HAR 1.2 — the format Chrome DevTools, Charles,
/// Postman, Insomnia, and Fiddler all import natively. Sharing a `.har` file
/// is the universal way to hand a backend engineer "exactly what my app did."
class NWHarExporter {
  final NWMasker masker;
  final String creatorName;
  final String creatorVersion;

  const NWHarExporter({
    required this.masker,
    this.creatorName = 'flutter_netwatch',
    this.creatorVersion = '0.1.0',
  });

  String exportAll(List<NWTransaction> transactions, {required bool masked}) {
    final entries =
        transactions.map((t) => _buildEntry(t, masked: masked)).toList();
    final har = <String, dynamic>{
      'log': <String, dynamic>{
        'version': '1.2',
        'creator': <String, dynamic>{
          'name': creatorName,
          'version': creatorVersion,
        },
        'entries': entries,
      },
    };
    return const JsonEncoder.withIndent('  ').convert(har);
  }

  String exportSingle(NWTransaction transaction, {required bool masked}) {
    return exportAll([transaction], masked: masked);
  }

  Map<String, dynamic> _buildEntry(
    NWTransaction transaction, {
    required bool masked,
  }) {
    final request = transaction.request;
    final response = transaction.response;
    final url = masked ? masker.maskUrl(request.url) : request.url;
    final reqHeaders =
        masked ? masker.maskHeaders(request.headers) : request.headers;
    final reqBody = masked ? masker.maskBody(request.body) : request.body;
    final durationMs = response?.duration.inMilliseconds ?? 0;

    return <String, dynamic>{
      'startedDateTime': transaction.createdAt.toUtc().toIso8601String(),
      'time': durationMs,
      'request': _buildHarRequest(request, url, reqHeaders, reqBody),
      'response': _buildHarResponse(transaction, masked: masked),
      'cache': <String, dynamic>{},
      'timings': <String, dynamic>{
        'send': 0,
        'wait': durationMs,
        'receive': 0,
      },
    };
  }

  Map<String, dynamic> _buildHarRequest(
    NWRequest request,
    Uri url,
    Map<String, String> headers,
    Object? body,
  ) {
    final result = <String, dynamic>{
      'method': request.method,
      'url': url.toString(),
      'httpVersion': 'HTTP/1.1',
      'cookies': const <dynamic>[],
      'headers': [
        for (final entry in headers.entries)
          <String, dynamic>{'name': entry.key, 'value': entry.value},
      ],
      'queryString': [
        for (final entry in url.queryParameters.entries)
          <String, dynamic>{'name': entry.key, 'value': entry.value},
      ],
      'headersSize': -1,
      'bodySize': -1,
    };

    if (body != null) {
      final mime = headers['content-type'] ?? headers['Content-Type'] ?? '';
      result['postData'] = <String, dynamic>{
        'mimeType': mime,
        'text': _stringifyBody(body),
      };
    }

    return result;
  }

  Map<String, dynamic> _buildHarResponse(
    NWTransaction transaction, {
    required bool masked,
  }) {
    final response = transaction.response;
    if (response == null) {
      return <String, dynamic>{
        'status': 0,
        'statusText': 'Pending',
        'httpVersion': 'HTTP/1.1',
        'cookies': const <dynamic>[],
        'headers': const <dynamic>[],
        'content': <String, dynamic>{
          'size': 0,
          'mimeType': '',
          'text': '',
        },
        'redirectURL': '',
        'headersSize': -1,
        'bodySize': -1,
      };
    }

    final headers = masked
        ? masker.maskHeaders(response.headers)
        : response.headers;
    final mime = headers['content-type'] ?? headers['Content-Type'] ?? '';
    final body = _bodyOf(response, masked: masked);
    final bodyText = _stringifyBody(body);
    final redirect = switch (response) {
      NWRedirectResponse r => r.location,
      _ => '',
    };

    return <String, dynamic>{
      'status': transaction.statusCode ?? 0,
      'statusText': _statusText(transaction.statusCode),
      'httpVersion': 'HTTP/1.1',
      'cookies': const <dynamic>[],
      'headers': [
        for (final entry in headers.entries)
          <String, dynamic>{'name': entry.key, 'value': entry.value},
      ],
      'content': <String, dynamic>{
        'size': response.contentLength ?? bodyText.length,
        'mimeType': mime,
        'text': bodyText,
      },
      'redirectURL': redirect,
      'headersSize': -1,
      'bodySize': -1,
    };
  }

  Object? _bodyOf(NWResponse response, {required bool masked}) {
    final raw = switch (response) {
      NWSuccessResponse r => r.body,
      NWRedirectResponse() => null,
      NWClientErrorResponse r => r.body,
      NWServerErrorResponse r => r.body,
      NWNetworkErrorResponse r => 'Network error: ${r.errorMessage}',
    };
    return masked ? masker.maskBody(raw) : raw;
  }

  String _stringifyBody(Object? body) {
    if (body == null) return '';
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  String _statusText(int? code) {
    if (code == null) return '';
    return switch (code) {
      200 => 'OK',
      201 => 'Created',
      202 => 'Accepted',
      204 => 'No Content',
      301 => 'Moved Permanently',
      302 => 'Found',
      304 => 'Not Modified',
      400 => 'Bad Request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not Found',
      408 => 'Request Timeout',
      409 => 'Conflict',
      422 => 'Unprocessable Entity',
      429 => 'Too Many Requests',
      500 => 'Internal Server Error',
      502 => 'Bad Gateway',
      503 => 'Service Unavailable',
      504 => 'Gateway Timeout',
      _ => '',
    };
  }
}
