/// Sealed request hierarchy describing every HTTP method NetWatch captures.
sealed class NWRequest {
  final String id;
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final Object? body;
  final DateTime timestamp;

  const NWRequest({
    required this.id,
    required this.method,
    required this.url,
    required this.headers,
    required this.body,
    required this.timestamp,
  });
}

/// HTTP `GET` request — body is always null.
final class NWGetRequest extends NWRequest {
  const NWGetRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.timestamp,
  }) : super(method: 'GET', body: null);
}

/// HTTP `POST` request — used for creating resources or sending arbitrary
/// payloads.
final class NWPostRequest extends NWRequest {
  const NWPostRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.body,
    required super.timestamp,
  }) : super(method: 'POST');
}

/// HTTP `PUT` request — replaces a resource at the target URL.
final class NWPutRequest extends NWRequest {
  const NWPutRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.body,
    required super.timestamp,
  }) : super(method: 'PUT');
}

/// HTTP `PATCH` request — applies a partial update to the target resource.
final class NWPatchRequest extends NWRequest {
  const NWPatchRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.body,
    required super.timestamp,
  }) : super(method: 'PATCH');
}

/// HTTP `DELETE` request — removes the target resource.
final class NWDeleteRequest extends NWRequest {
  const NWDeleteRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.body,
    required super.timestamp,
  }) : super(method: 'DELETE');
}

/// HTTP `HEAD` request — like GET but the server returns no body.
final class NWHeadRequest extends NWRequest {
  const NWHeadRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.timestamp,
  }) : super(method: 'HEAD', body: null);
}

/// HTTP `OPTIONS` request — used for CORS preflight and capability discovery.
final class NWOptionsRequest extends NWRequest {
  const NWOptionsRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.timestamp,
  }) : super(method: 'OPTIONS', body: null);
}

/// `multipart/form-data` request — used for file uploads. Carries [files]
/// and a parallel map of plain-text [fields].
final class NWMultipartRequest extends NWRequest {
  final List<NWMultipartFile> files;
  final Map<String, String> fields;

  const NWMultipartRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.timestamp,
    required this.files,
    this.fields = const {},
  }) : super(method: 'POST', body: null);
}

/// Metadata about one file inside a [NWMultipartRequest]. The actual bytes
/// aren't stored — only enough to render and export the request.
class NWMultipartFile {
  final String fieldName;
  final String fileName;
  final int sizeBytes;
  final String contentType;

  const NWMultipartFile({
    required this.fieldName,
    required this.fileName,
    required this.sizeBytes,
    required this.contentType,
  });
}
