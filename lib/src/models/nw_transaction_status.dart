/// Sealed status describing the lifecycle of a captured transaction.
sealed class NWTransactionStatus {
  const NWTransactionStatus();
}

/// The request has been fired but no response has arrived yet.
final class NWStatusPending extends NWTransactionStatus {
  const NWStatusPending();
}

/// 2xx/3xx response within the configured performance budget.
final class NWStatusSuccess extends NWTransactionStatus {
  final int statusCode;
  final Duration duration;

  const NWStatusSuccess({
    required this.statusCode,
    required this.duration,
  });
}

/// 4xx or 5xx response — the server replied but with an error code.
final class NWStatusError extends NWTransactionStatus {
  final int? statusCode;
  final String message;

  const NWStatusError({
    required this.statusCode,
    required this.message,
  });
}

/// 2xx response that arrived but exceeded the configured [budgetMs] —
/// surfaced as a perf warning rather than a hard failure.
final class NWStatusSlow extends NWTransactionStatus {
  final int statusCode;
  final Duration duration;
  final int budgetMs;

  const NWStatusSlow({
    required this.statusCode,
    required this.duration,
    required this.budgetMs,
  });
}

/// The request never reached a server (DNS, timeout, dropped connection).
final class NWStatusNetworkError extends NWTransactionStatus {
  final String message;

  const NWStatusNetworkError({required this.message});
}
