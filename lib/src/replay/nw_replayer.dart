import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../models/nw_request.dart';

/// Replays a captured request through a real HTTP client. Implementations
/// re-fire the request through the same client used originally, so the new
/// request flows back through NetWatch's interceptor and shows up as a fresh
/// transaction.
abstract class NWReplayer {
  /// Whether this replayer can re-fire the given captured request.
  bool canHandle(NWRequest request);

  /// Re-fire the request. Errors are caught by the caller — implementations
  /// should let exceptions propagate.
  Future<void> replay(NWRequest request);
}

/// Replays through a Dio instance. Pair with [NWDioInterceptor] so the new
/// request is captured.
class NWDioReplayer implements NWReplayer {
  final Dio dio;
  final bool Function(NWRequest)? matcher;

  NWDioReplayer(this.dio, {this.matcher});

  @override
  bool canHandle(NWRequest request) {
    if (matcher != null) return matcher!(request);
    return true;
  }

  @override
  Future<void> replay(NWRequest request) async {
    final options = Options(
      method: request.method,
      headers: Map<String, dynamic>.from(request.headers),
    );
    await dio.requestUri<dynamic>(
      request.url,
      data: request.body,
      options: options,
    );
  }
}

/// Replays through a [http.Client]. The client should be the one wrapped by
/// [NetWatch.httpClient] so the replay is also captured.
class NWHttpClientReplayer implements NWReplayer {
  final http.Client client;
  final bool Function(NWRequest)? matcher;

  NWHttpClientReplayer(this.client, {this.matcher});

  @override
  bool canHandle(NWRequest request) {
    if (matcher != null) return matcher!(request);
    return true;
  }

  @override
  Future<void> replay(NWRequest request) async {
    final method = request.method.toUpperCase();
    final headers = Map<String, String>.from(request.headers);
    final body = request.body;

    Future<http.Response> send() {
      switch (method) {
        case 'GET':
          return client.get(request.url, headers: headers);
        case 'HEAD':
          return client.head(request.url, headers: headers);
        case 'POST':
          return client.post(
            request.url,
            headers: headers,
            body: _encodeBody(body),
          );
        case 'PUT':
          return client.put(
            request.url,
            headers: headers,
            body: _encodeBody(body),
          );
        case 'PATCH':
          return client.patch(
            request.url,
            headers: headers,
            body: _encodeBody(body),
          );
        case 'DELETE':
          return client.delete(
            request.url,
            headers: headers,
            body: _encodeBody(body),
          );
        default:
          return client.get(request.url, headers: headers);
      }
    }

    await send();
  }

  Object? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    if (body is List<int>) return body;
    if (body is Map<String, String>) return body;
    return body.toString();
  }
}

/// User-supplied replayer for fully-custom HTTP clients (Chopper, GraphQL
/// clients, etc.). Provide a callback that re-fires the request.
class NWCustomReplayer implements NWReplayer {
  final bool Function(NWRequest) _canHandle;
  final Future<void> Function(NWRequest) _replay;

  NWCustomReplayer({
    required bool Function(NWRequest) canHandle,
    required Future<void> Function(NWRequest) replay,
  })  : _canHandle = canHandle,
        _replay = replay;

  @override
  bool canHandle(NWRequest request) => _canHandle(request);

  @override
  Future<void> replay(NWRequest request) => _replay(request);
}
