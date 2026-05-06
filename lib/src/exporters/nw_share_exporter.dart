import 'dart:convert';

import '../masking/nw_masker.dart';
import '../models/nw_response.dart';
import '../models/nw_transaction.dart';

class NWShareExporter {
  final NWMasker masker;

  const NWShareExporter({required this.masker});

  String exportAsText(NWTransaction transaction, {required bool masked}) {
    final request = transaction.request;
    final url = masked ? masker.maskUrl(request.url) : request.url;
    final reqHeaders =
        masked ? masker.maskHeaders(request.headers) : request.headers;
    final body = masked ? masker.maskBody(request.body) : request.body;
    final buffer = StringBuffer();

    buffer.writeln('=== NetWatch Export ===');
    buffer.writeln('${request.method} $url');
    buffer.writeln('Time: ${transaction.createdAt.toIso8601String()}');
    buffer.writeln('Status: ${transaction.statusLabel}');
    buffer.writeln(
      'Duration: ${transaction.response?.duration.inMilliseconds ?? '-'}ms',
    );
    buffer.writeln();
    buffer.writeln('--- REQUEST HEADERS ---');
    if (reqHeaders.isEmpty) {
      buffer.writeln('(none)');
    } else {
      reqHeaders.forEach((k, v) => buffer.writeln('$k: $v'));
    }

    if (body != null) {
      buffer.writeln();
      buffer.writeln('--- REQUEST BODY ---');
      buffer.writeln(_format(body));
    }

    final response = transaction.response;
    if (response != null) {
      final resHeaders =
          masked ? masker.maskHeaders(response.headers) : response.headers;
      buffer.writeln();
      buffer.writeln('--- RESPONSE HEADERS ---');
      if (resHeaders.isEmpty) {
        buffer.writeln('(none)');
      } else {
        resHeaders.forEach((k, v) => buffer.writeln('$k: $v'));
      }
      buffer.writeln();
      buffer.writeln('--- RESPONSE BODY ---');
      buffer.writeln(switch (response) {
        NWSuccessResponse r => _format(r.body),
        NWRedirectResponse r => 'Redirect → ${r.location}',
        NWClientErrorResponse r => _format(r.body) ?? 'No body',
        NWServerErrorResponse r => _format(r.body) ?? 'No body',
        NWNetworkErrorResponse r => 'Network error: ${r.errorMessage}',
      });
    }

    return buffer.toString();
  }

  String? _format(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }
}
