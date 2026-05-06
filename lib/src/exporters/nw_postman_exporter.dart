import 'dart:convert';

import '../masking/nw_masker.dart';
import '../models/nw_response.dart';
import '../models/nw_transaction.dart';

class NWPostmanExporter {
  final NWMasker masker;

  const NWPostmanExporter({required this.masker});

  String exportCollection(
    List<NWTransaction> transactions, {
    String collectionName = 'NetWatch Export',
    required bool masked,
  }) {
    final items =
        transactions.map((t) => _buildItem(t, masked: masked)).toList();

    final collection = <String, dynamic>{
      'info': <String, dynamic>{
        'name': collectionName,
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
        '_postman_id': DateTime.now().microsecondsSinceEpoch.toString(),
      },
      'item': items,
    };

    return const JsonEncoder.withIndent('  ').convert(collection);
  }

  String exportSingle(NWTransaction transaction, {required bool masked}) {
    return const JsonEncoder.withIndent('  ')
        .convert(_buildItem(transaction, masked: masked));
  }

  Map<String, dynamic> _buildItem(
    NWTransaction transaction, {
    required bool masked,
  }) {
    final request = transaction.request;
    final url = masked ? masker.maskUrl(request.url) : request.url;
    final headers =
        masked ? masker.maskHeaders(request.headers) : request.headers;
    final body = masked ? masker.maskBody(request.body) : request.body;

    final pathSegments = url.pathSegments.isEmpty
        ? <String>[]
        : List<String>.from(url.pathSegments);

    final item = <String, dynamic>{
      'name': '${request.method} ${url.path.isEmpty ? '/' : url.path}',
      'request': <String, dynamic>{
        'method': request.method,
        'header': [
          for (final entry in headers.entries)
            <String, dynamic>{
              'key': entry.key,
              'value': entry.value,
              'type': 'text',
            },
        ],
        'url': <String, dynamic>{
          'raw': url.toString(),
          'protocol': url.scheme,
          'host': url.host.split('.'),
          if (url.hasPort) 'port': url.port.toString(),
          'path': pathSegments,
          if (url.queryParameters.isNotEmpty)
            'query': [
              for (final entry in url.queryParameters.entries)
                <String, dynamic>{
                  'key': entry.key,
                  'value': entry.value,
                },
            ],
        },
        if (body != null)
          'body': <String, dynamic>{
            'mode': 'raw',
            'raw': body is String ? body : jsonEncode(body),
            'options': <String, dynamic>{
              'raw': <String, dynamic>{'language': 'json'},
            },
          },
      },
    };

    if (transaction.response != null) {
      item['response'] = [_buildResponse(transaction, masked: masked)];
    }

    return item;
  }

  Map<String, dynamic> _buildResponse(
    NWTransaction transaction, {
    required bool masked,
  }) {
    final response = transaction.response!;
    final headers =
        masked ? masker.maskHeaders(response.headers) : response.headers;

    return <String, dynamic>{
      'name': 'Response',
      'status': transaction.statusLabel,
      'code': transaction.statusCode ?? 0,
      'header': [
        for (final entry in headers.entries)
          <String, dynamic>{'key': entry.key, 'value': entry.value},
      ],
      'body': switch (response) {
        NWSuccessResponse r => _bodyToString(r.body),
        NWRedirectResponse() => '',
        NWClientErrorResponse r => _bodyToString(r.body),
        NWServerErrorResponse r => _bodyToString(r.body),
        NWNetworkErrorResponse r => 'Error: ${r.errorMessage}',
      },
    };
  }

  String _bodyToString(Object? body) {
    if (body == null) return '';
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }
}
