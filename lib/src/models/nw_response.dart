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
