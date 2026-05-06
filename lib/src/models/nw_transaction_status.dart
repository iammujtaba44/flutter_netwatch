/// Sealed status describing the lifecycle of a captured transaction.
sealed class NWTransactionStatus {
  const NWTransactionStatus();
}

final class NWStatusPending extends NWTransactionStatus {
  const NWStatusPending();
}

final class NWStatusSuccess extends NWTransactionStatus {
  final int statusCode;
  final Duration duration;

  const NWStatusSuccess({
    required this.statusCode,
    required this.duration,
  });
}

final class NWStatusError extends NWTransactionStatus {
  final int? statusCode;
  final String message;

  const NWStatusError({
    required this.statusCode,
    required this.message,
  });
}

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

final class NWStatusNetworkError extends NWTransactionStatus {
  final String message;

  const NWStatusNetworkError({required this.message});
}
