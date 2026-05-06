import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';

import '../core/netwatch_core.dart';
import '../models/nw_request.dart';
import '../models/nw_response.dart';
import '../models/nw_security_analysis.dart';
import '../models/nw_transaction.dart';
import '../models/nw_transaction_status.dart';

/// Chopper interceptor that captures every request and response that passes
/// through a [ChopperClient]. Add it to your client's `interceptors` list.
class NWChopperInterceptor implements Interceptor {
  static final Map<String, _PendingMeta> _pending = <String, _PendingMeta>{};

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(
    Chain<BodyType> chain,
  ) async {
    if (kReleaseMode || !NetWatchCore.instance.isActive) {
      return chain.proceed(chain.request);
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final stopwatch = Stopwatch()..start();
    final request = chain.request;

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
      _pending[id] = _PendingMeta(stopwatch);
    } catch (_) {}

    try {
      final response = await chain.proceed(request);
      stopwatch.stop();
      try {
        final nwResponse = _buildResponse(response, stopwatch.elapsed);
        NetWatchCore.instance.updateTransaction(id, nwResponse);
      } catch (_) {}
      _pending.remove(id);
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
      _pending.remove(id);
      rethrow;
    }
  }

  NWRequest _buildRequest(String id, Request request) {
    final headers = Map<String, String>.from(request.headers);
    final timestamp = DateTime.now();
    final url = request.url;

    Object? body = request.body;
    if (body is String) {
      final contentType =
          (headers['content-type'] ?? headers['Content-Type'] ?? '')
              .toLowerCase();
      if (contentType.contains('application/json')) {
        try {
          body = jsonDecode(body);
        } catch (_) {}
      }
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

  NWResponse _buildResponse(Response<dynamic> response, Duration duration) {
    final headers = Map<String, String>.from(response.headers);
    final code = response.statusCode;
    final contentLength = int.tryParse(headers['content-length'] ?? '');

    Object? body = response.body;
    if (body is String) {
      final contentType = (headers['content-type'] ?? '').toLowerCase();
      if (contentType.contains('application/json')) {
        try {
          body = jsonDecode(body);
        } catch (_) {}
      }
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
}

class _PendingMeta {
  final Stopwatch stopwatch;
  _PendingMeta(this.stopwatch);
}
