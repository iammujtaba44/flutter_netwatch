import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/netwatch_core.dart';
import '../models/nw_request.dart';
import '../models/nw_response.dart';
import '../models/nw_security_analysis.dart';
import '../models/nw_transaction.dart';
import '../models/nw_transaction_status.dart';

/// Drop-in `http.Client` wrapper that captures every request fired through it.
/// Pass an existing client (or omit to wrap a fresh one).
class NWHttpClient extends http.BaseClient {
  /// The underlying client this wrapper delegates to.
  final http.Client _inner;

  /// Wraps [inner] so every request and response goes through NetWatch.
  NWHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (kReleaseMode || !NetWatchCore.instance.isActive) {
      return _inner.send(request);
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final stopwatch = Stopwatch()..start();

    try {
      final nwRequest = _buildRequest(id, request);
      final transaction = NWTransaction(
        id: id,
        request: nwRequest,
        response: null,
        status: const NWStatusPending(),
        security: NWSecurityAnalysis.analyze(nwRequest),
        createdAt: DateTime.now(),
      );
      NetWatchCore.instance.addTransaction(transaction);
    } catch (_) {}

    try {
      final response = await _inner.send(request);
      stopwatch.stop();
      try {
        final nwResponse = await _buildResponse(response, stopwatch.elapsed);
        NetWatchCore.instance.updateTransaction(id, nwResponse);
      } catch (_) {}
      return response;
    } catch (e) {
      stopwatch.stop();
      try {
        NetWatchCore.instance.updateTransaction(
          id,
          NWNetworkErrorResponse(
            errorMessage: e.toString(),
            originalError: e,
            duration: stopwatch.elapsed,
          ),
        );
      } catch (_) {}
      rethrow;
    }
  }

  NWRequest _buildRequest(String id, http.BaseRequest request) {
    final headers = Map<String, String>.from(request.headers);
    final timestamp = DateTime.now();
    final url = request.url;

    Object? body;
    if (request is http.Request) {
      body = _decodeBody(request.body, headers);
    } else if (request is http.MultipartRequest) {
      return NWMultipartRequest(
        id: id,
        url: url,
        headers: headers,
        timestamp: timestamp,
        files: request.files
            .map((f) => NWMultipartFile(
                  fieldName: f.field,
                  fileName: f.filename ?? 'file',
                  sizeBytes: f.length,
                  contentType: f.contentType.toString(),
                ))
            .toList(),
        fields: Map<String, String>.from(request.fields),
      );
    }

    return switch (request.method.toUpperCase()) {
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

  Object? _decodeBody(String body, Map<String, String> headers) {
    if (body.isEmpty) return null;
    final contentType =
        (headers['content-type'] ?? headers['Content-Type'] ?? '')
            .toLowerCase();
    if (contentType.contains('application/json')) {
      try {
        return jsonDecode(body);
      } catch (_) {
        return body;
      }
    }
    return body;
  }

  Future<NWResponse> _buildResponse(
    http.StreamedResponse response,
    Duration duration,
  ) async {
    final headers = Map<String, String>.from(response.headers);
    final code = response.statusCode;
    final contentLength = response.contentLength;

    Object? body;
    try {
      final bytes = await response.stream.toBytes();
      final text = utf8.decode(bytes, allowMalformed: true);
      final contentType = (headers['content-type'] ?? '').toLowerCase();
      if (contentType.contains('application/json')) {
        try {
          body = jsonDecode(text);
        } catch (_) {
          body = text;
        }
      } else {
        body = text;
      }
    } catch (_) {
      body = null;
    }

    if (code >= 200 && code < 300) {
      return NWSuccessResponse(
        statusCode: code,
        body: body,
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
        body: body,
        headers: headers,
        duration: duration,
        contentLength: contentLength,
      );
    }
    return NWServerErrorResponse(
      statusCode: code,
      body: body,
      headers: headers,
      duration: duration,
      contentLength: contentLength,
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
