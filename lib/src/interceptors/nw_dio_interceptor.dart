import 'package:dio/dio.dart';

import '../core/netwatch_core.dart';
import '../models/nw_request.dart';
import '../models/nw_response.dart';
import '../models/nw_security_analysis.dart';
import '../models/nw_transaction.dart';
import '../models/nw_transaction_status.dart';

/// Dio interceptor that captures every request, response, and error that
/// passes through a [Dio] instance. Add it to `dio.interceptors`.
class NWDioInterceptor extends Interceptor {
  static const String _idKey = '_nw_id';
  static const String _startKey = '_nw_start';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!NetWatchCore.instance.isActive) {
      handler.next(options);
      return;
    }

    try {
      final id = _generateId();
      options.extra[_idKey] = id;
      options.extra[_startKey] = DateTime.now().microsecondsSinceEpoch;

      final request = _buildRequest(id, options);
      final transaction = NWTransaction(
        id: id,
        request: request,
        response: null,
        status: const NWStatusPending(),
        security: NWSecurityAnalysis.analyze(request),
        createdAt: DateTime.now(),
      );
      NetWatchCore.instance.addTransaction(transaction);
    } catch (_) {}

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (!NetWatchCore.instance.isActive) {
      handler.next(response);
      return;
    }

    try {
      final id = response.requestOptions.extra[_idKey] as String?;
      if (id != null) {
        final duration = _computeDuration(response.requestOptions);
        final nwResponse = _buildResponse(response, duration);
        NetWatchCore.instance.updateTransaction(id, nwResponse);
      }
    } catch (_) {}

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (!NetWatchCore.instance.isActive) {
      handler.next(err);
      return;
    }

    try {
      final id = err.requestOptions.extra[_idKey] as String?;
      if (id != null) {
        final duration = _computeDuration(err.requestOptions);
        final nwResponse = _buildErrorResponse(err, duration);
        NetWatchCore.instance.updateTransaction(id, nwResponse);
      }
    } catch (_) {}

    handler.next(err);
  }

  Duration _computeDuration(RequestOptions options) {
    final start = options.extra[_startKey];
    if (start is int) {
      final elapsed = DateTime.now().microsecondsSinceEpoch - start;
      return Duration(microseconds: elapsed);
    }
    return Duration.zero;
  }

  NWRequest _buildRequest(String id, RequestOptions options) {
    final headers = _flattenHeaders(options.headers);
    final timestamp = DateTime.now();
    final url = options.uri;

    final body = _extractBody(options.data);

    return switch (options.method.toUpperCase()) {
      'GET' => NWGetRequest(
          id: id,
          url: url,
          headers: headers,
          timestamp: timestamp,
        ),
      'POST' => NWPostRequest(
          id: id,
          url: url,
          headers: headers,
          body: body,
          timestamp: timestamp,
        ),
      'PUT' => NWPutRequest(
          id: id,
          url: url,
          headers: headers,
          body: body,
          timestamp: timestamp,
        ),
      'PATCH' => NWPatchRequest(
          id: id,
          url: url,
          headers: headers,
          body: body,
          timestamp: timestamp,
        ),
      'DELETE' => NWDeleteRequest(
          id: id,
          url: url,
          headers: headers,
          body: body,
          timestamp: timestamp,
        ),
      'HEAD' => NWHeadRequest(
          id: id,
          url: url,
          headers: headers,
          timestamp: timestamp,
        ),
      'OPTIONS' => NWOptionsRequest(
          id: id,
          url: url,
          headers: headers,
          timestamp: timestamp,
        ),
      _ => NWPostRequest(
          id: id,
          url: url,
          headers: headers,
          body: body,
          timestamp: timestamp,
        ),
    };
  }

  Object? _extractBody(Object? data) {
    if (data == null) return null;
    if (data is FormData) {
      return {
        'fields': {for (final f in data.fields) f.key: f.value},
        'files': data.files
            .map((f) => {
                  'name': f.value.filename ?? 'file',
                  'length': f.value.length,
                })
            .toList(),
      };
    }
    return data;
  }

  NWResponse _buildResponse(Response<dynamic> response, Duration duration) {
    final headers = _flattenHeaders(response.headers.map);
    final code = response.statusCode ?? 0;
    final contentLength = _parseContentLength(headers);

    if (code >= 200 && code < 300) {
      return NWSuccessResponse(
        statusCode: code,
        body: response.data,
        headers: headers,
        duration: duration,
        contentLength: contentLength,
      );
    }
    if (code >= 300 && code < 400) {
      return NWRedirectResponse(
        statusCode: code,
        location: headers['location'] ?? '',
        headers: headers,
        duration: duration,
        contentLength: contentLength,
      );
    }
    if (code >= 400 && code < 500) {
      return NWClientErrorResponse(
        statusCode: code,
        body: response.data,
        headers: headers,
        duration: duration,
        contentLength: contentLength,
      );
    }
    return NWServerErrorResponse(
      statusCode: code,
      body: response.data,
      headers: headers,
      duration: duration,
      contentLength: contentLength,
    );
  }

  NWResponse _buildErrorResponse(DioException err, Duration duration) {
    final response = err.response;
    if (response != null) {
      return _buildResponse(response, duration);
    }
    return NWNetworkErrorResponse(
      errorMessage: err.message ?? err.type.name,
      originalError: err.error,
      duration: duration,
    );
  }

  Map<String, String> _flattenHeaders(Map<String, dynamic> headers) {
    final result = <String, String>{};
    for (final entry in headers.entries) {
      final value = entry.value;
      if (value is List) {
        result[entry.key] = value.join(', ');
      } else {
        result[entry.key] = value.toString();
      }
    }
    return result;
  }

  int? _parseContentLength(Map<String, String> headers) {
    final raw = headers['content-length'] ?? headers['Content-Length'];
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}
