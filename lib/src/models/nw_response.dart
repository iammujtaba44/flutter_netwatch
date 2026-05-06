/// Sealed response hierarchy covering every outcome NetWatch records.
sealed class NWResponse {
  final Map<String, String> headers;
  final Duration duration;
  final int? contentLength;

  const NWResponse({
    required this.headers,
    required this.duration,
    required this.contentLength,
  });
}

/// 2xx response — the request completed successfully.
final class NWSuccessResponse extends NWResponse {
  final int statusCode;
  final Object? body;

  const NWSuccessResponse({
    required this.statusCode,
    required this.body,
    required super.headers,
    required super.duration,
    required super.contentLength,
  });
}

/// 3xx response — the server redirected the request to [location].
final class NWRedirectResponse extends NWResponse {
  final int statusCode;
  final String location;

  const NWRedirectResponse({
    required this.statusCode,
    required this.location,
    required super.headers,
    required super.duration,
    required super.contentLength,
  });
}

/// 4xx response — the request failed because of something on the client side
/// (bad request, unauthorized, not found, etc.).
final class NWClientErrorResponse extends NWResponse {
  final int statusCode;
  final Object? body;

  const NWClientErrorResponse({
    required this.statusCode,
    required this.body,
    required super.headers,
    required super.duration,
    required super.contentLength,
  });
}

/// 5xx response — the server failed to fulfil an apparently-valid request.
final class NWServerErrorResponse extends NWResponse {
  final int statusCode;
  final Object? body;

  const NWServerErrorResponse({
    required this.statusCode,
    required this.body,
    required super.headers,
    required super.duration,
    required super.contentLength,
  });
}

/// The request never reached a server — DNS failure, timeout, dropped
/// connection, TLS handshake failure, etc.
final class NWNetworkErrorResponse extends NWResponse {
  final String errorMessage;
  final Object? originalError;

  const NWNetworkErrorResponse({
    required this.errorMessage,
    required this.originalError,
    super.duration = Duration.zero,
  }) : super(
          headers: const {},
          contentLength: null,
        );
}
