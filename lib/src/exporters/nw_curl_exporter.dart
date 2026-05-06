import 'dart:convert';

import '../masking/nw_masker.dart';
import '../models/nw_request.dart';
import '../models/nw_transaction.dart';

class NWCurlExporter {
  final NWMasker masker;

  const NWCurlExporter({required this.masker});

  String export(NWTransaction transaction, {required bool masked}) {
    final request = transaction.request;
    final url = masked ? masker.maskUrl(request.url) : request.url;
    final headers =
        masked ? masker.maskHeaders(request.headers) : request.headers;
    final body = masked ? masker.maskBody(request.body) : request.body;

    final buffer = StringBuffer();
    buffer.write("curl -X ${request.method} '${url.toString()}'");

    for (final entry in headers.entries) {
      final value = entry.value.replaceAll("'", r"'\''");
      buffer.write(" \\\n  -H '${entry.key}: $value'");
    }

    if (body != null) {
      final bodyStr = _stringifyBody(body);
      final escaped = bodyStr.replaceAll("'", r"'\''");
      buffer.write(" \\\n  --data-raw '$escaped'");
    }

    if (request is NWMultipartRequest) {
      for (final field in request.fields.entries) {
        buffer.write(" \\\n  -F '${field.key}=${field.value}'");
      }
      for (final file in request.files) {
        buffer
            .write(" \\\n  -F '${file.fieldName}=@/path/to/${file.fileName}'");
      }
    }

    return buffer.toString();
  }

  String _stringifyBody(Object body) {
    if (body is String) return body;
    if (body is Map || body is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(body);
      } catch (_) {
        return body.toString();
      }
    }
    return body.toString();
  }
}
