import 'package:flutter/material.dart';
import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    NetWatch.initialize(
      config: const NetWatchConfig(performanceBudgetMs: 1000),
    );
  });

  NWTransaction makeTx({NWResponse? response}) {
    final req = NWGetRequest(
      id: '1',
      url: Uri.parse('https://api.example.com/x'),
      headers: const {},
      timestamp: DateTime(2024, 1, 1),
    );
    return NWTransaction(
      id: '1',
      request: req,
      response: response,
      status: response == null
          ? const NWStatusPending()
          : const NWStatusSuccess(
              statusCode: 200,
              duration: Duration(milliseconds: 50),
            ),
      security: NWSecurityAnalysis.analyze(req),
      createdAt: DateTime(2024, 1, 1),
    );
  }

  test('statusCode resolves correctly for success', () {
    final tx = makeTx(
      response: const NWSuccessResponse(
        statusCode: 200,
        body: 'ok',
        headers: {},
        duration: Duration(milliseconds: 100),
        contentLength: null,
      ),
    );
    expect(tx.statusCode, 200);
  });

  test('statusCode resolves for redirect/client/server', () {
    expect(
      makeTx(
        response: const NWRedirectResponse(
          statusCode: 301,
          location: '/other',
          headers: {},
          duration: Duration.zero,
          contentLength: null,
        ),
      ).statusCode,
      301,
    );
    expect(
      makeTx(
        response: const NWClientErrorResponse(
          statusCode: 404,
          body: null,
          headers: {},
          duration: Duration.zero,
          contentLength: null,
        ),
      ).statusCode,
      404,
    );
    expect(
      makeTx(
        response: const NWServerErrorResponse(
          statusCode: 500,
          body: null,
          headers: {},
          duration: Duration.zero,
          contentLength: null,
        ),
      ).statusCode,
      500,
    );
  });

  test('statusCode null for network error', () {
    final tx = makeTx(
      response: const NWNetworkErrorResponse(
        errorMessage: 'down',
        originalError: null,
      ),
    );
    expect(tx.statusCode, null);
  });

  test('statusColor green for 2xx', () {
    final tx = makeTx(
      response: const NWSuccessResponse(
        statusCode: 200,
        body: '',
        headers: {},
        duration: Duration.zero,
        contentLength: null,
      ),
    );
    expect(tx.statusColor, const Color(0xFF4CAF50));
  });

  test('statusColor orange for 4xx', () {
    final tx = makeTx(
      response: const NWClientErrorResponse(
        statusCode: 404,
        body: null,
        headers: {},
        duration: Duration.zero,
        contentLength: null,
      ),
    );
    expect(tx.statusColor, const Color(0xFFFF9800));
  });

  test('statusColor red for 5xx', () {
    final tx = makeTx(
      response: const NWServerErrorResponse(
        statusCode: 500,
        body: null,
        headers: {},
        duration: Duration.zero,
        contentLength: null,
      ),
    );
    expect(tx.statusColor, const Color(0xFFF44336));
  });

  test('isPending true when response null', () {
    expect(makeTx().isPending, true);
  });

  test('isSlow true when duration exceeds budget', () {
    final base = makeTx();
    final slow = base.copyWithResponse(
      const NWSuccessResponse(
        statusCode: 200,
        body: '',
        headers: {},
        duration: Duration(milliseconds: 5000),
        contentLength: null,
      ),
    );
    expect(slow.isSlow, true);
    expect(slow.status, isA<NWStatusSlow>());
  });

  test('copyWithResponse produces NWStatusSuccess for fast 200', () {
    final base = makeTx();
    final updated = base.copyWithResponse(
      const NWSuccessResponse(
        statusCode: 200,
        body: '',
        headers: {},
        duration: Duration(milliseconds: 50),
        contentLength: null,
      ),
    );
    expect(updated.status, isA<NWStatusSuccess>());
  });

  test('copyWithResponse produces NWStatusError for client error', () {
    final base = makeTx();
    final updated = base.copyWithResponse(
      const NWClientErrorResponse(
        statusCode: 404,
        body: null,
        headers: {},
        duration: Duration(milliseconds: 50),
        contentLength: null,
      ),
    );
    expect(updated.status, isA<NWStatusError>());
    expect(updated.isError, true);
  });
}
