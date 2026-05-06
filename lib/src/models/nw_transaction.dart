import 'package:flutter/material.dart';

import '../core/netwatch_core.dart';
import 'nw_request.dart';
import 'nw_response.dart';
import 'nw_security_analysis.dart';
import 'nw_transaction_status.dart';

class NWTransaction {
  final String id;
  final NWRequest request;
  final NWResponse? response;
  final NWTransactionStatus status;
  final NWSecurityAnalysis security;
  final DateTime createdAt;

  const NWTransaction({
    required this.id,
    required this.request,
    required this.response,
    required this.status,
    required this.security,
    required this.createdAt,
  });

  bool get isPending => status is NWStatusPending;

  bool get isSlow => status is NWStatusSlow;

  bool get isError => switch (status) {
        NWStatusError() => true,
        NWStatusNetworkError() => true,
        _ => false,
      };

  int? get statusCode => switch (response) {
        NWSuccessResponse r => r.statusCode,
        NWRedirectResponse r => r.statusCode,
        NWClientErrorResponse r => r.statusCode,
        NWServerErrorResponse r => r.statusCode,
        NWNetworkErrorResponse() => null,
        null => null,
      };

  Color get statusColor {
    final code = statusCode;
    if (code == null) {
      return switch (status) {
        NWStatusPending() => const Color(0xFF9E9E9E),
        NWStatusNetworkError() => const Color(0xFFF44336),
        _ => const Color(0xFF9E9E9E),
      };
    }
    if (code >= 200 && code < 300) return const Color(0xFF4CAF50);
    if (code >= 300 && code < 400) return const Color(0xFF2196F3);
    if (code >= 400 && code < 500) return const Color(0xFFFF9800);
    if (code >= 500) return const Color(0xFFF44336);
    return const Color(0xFF9E9E9E);
  }

  String get statusLabel {
    final code = statusCode;
    if (code != null) return '$code';
    return switch (status) {
      NWStatusPending() => 'Pending',
      NWStatusNetworkError() => 'Error',
      _ => '???',
    };
  }

  Duration get duration => response?.duration ?? Duration.zero;

  NWTransaction copyWithResponse(NWResponse response) => NWTransaction(
        id: id,
        request: request,
        response: response,
        status: _resolveStatus(response),
        security: security,
        createdAt: createdAt,
      );

  NWTransactionStatus _resolveStatus(NWResponse response) {
    final budgetMs = NetWatchCore.instance.config.performanceBudgetMs;
    return switch (response) {
      NWSuccessResponse r when r.duration.inMilliseconds > budgetMs =>
        NWStatusSlow(
          statusCode: r.statusCode,
          duration: r.duration,
          budgetMs: budgetMs,
        ),
      NWSuccessResponse r => NWStatusSuccess(
          statusCode: r.statusCode,
          duration: r.duration,
        ),
      NWRedirectResponse r => NWStatusSuccess(
          statusCode: r.statusCode,
          duration: r.duration,
        ),
      NWClientErrorResponse r => NWStatusError(
          statusCode: r.statusCode,
          message: 'Client error',
        ),
      NWServerErrorResponse r => NWStatusError(
          statusCode: r.statusCode,
          message: 'Server error',
        ),
      NWNetworkErrorResponse r => NWStatusNetworkError(
          message: r.errorMessage,
        ),
    };
  }
}
