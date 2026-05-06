import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    NetWatch.initialize(
      config: const NetWatchConfig(performanceBudgetMs: 1000),
    );
    NetWatchCore.instance.clearAll();
  });

  Future<Dio> makeDio({
    required ResponseBody Function(RequestOptions) onFetch,
  }) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.interceptors.add(NWDioInterceptor());
    dio.httpClientAdapter = _StubAdapter(onFetch);
    return dio;
  }

  test('Captures GET request', () async {
    final dio = await makeDio(
      onFetch: (_) => ResponseBody.fromString(
        '{"ok":true}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      ),
    );
    await dio.get<dynamic>('/users');
    expect(NetWatch.transactions.length, 1);
    expect(NetWatch.transactions.first.request.method, 'GET');
  });

  test('Captures POST with body', () async {
    final dio = await makeDio(
      onFetch: (_) => ResponseBody.fromString(
        '{}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      ),
    );
    await dio.post<dynamic>('/users', data: {'name': 'John'});
    final tx = NetWatch.transactions.first;
    expect(tx.request, isA<NWPostRequest>());
    expect(tx.request.body, {'name': 'John'});
  });

  test('Captures response and updates transaction', () async {
    final dio = await makeDio(
      onFetch: (_) => ResponseBody.fromString(
        '"ok"',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      ),
    );
    await dio.get<dynamic>('/x');
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWSuccessResponse>());
    expect(tx.statusCode, 200);
  });

  test('Captures 404 as NWClientErrorResponse', () async {
    final dio = await makeDio(
      onFetch: (_) => ResponseBody.fromString(
        'not found',
        404,
        headers: {
          'content-type': ['text/plain'],
        },
      ),
    );
    try {
      await dio.get<dynamic>('/missing');
    } catch (_) {}
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWClientErrorResponse>());
  });

  test('Captures network error as NWNetworkErrorResponse', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.interceptors.add(NWDioInterceptor());
    dio.httpClientAdapter = _ThrowingAdapter();
    try {
      await dio.get<dynamic>('/x');
    } catch (_) {}
    final tx = NetWatch.transactions.first;
    expect(tx.response, isA<NWNetworkErrorResponse>());
  });

  test('Does not modify response data', () async {
    final dio = await makeDio(
      onFetch: (_) => ResponseBody.fromString(
        '{"value":42}',
        200,
        headers: {
          'content-type': ['application/json'],
        },
      ),
    );
    final response = await dio.get<dynamic>('/x');
    expect(response.statusCode, 200);
    expect(response.data, {'value': 42});
  });
}

class _StubAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) onFetch;

  _StubAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      message: 'no connection',
    );
  }

  @override
  void close({bool force = false}) {}
}
