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

final class NWGetRequest extends NWRequest {
  const NWGetRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.timestamp,
  }) : super(method: 'GET', body: null);
}

final class NWPostRequest extends NWRequest {
  const NWPostRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.body,
    required super.timestamp,
  }) : super(method: 'POST');
}

final class NWPutRequest extends NWRequest {
  const NWPutRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.body,
    required super.timestamp,
  }) : super(method: 'PUT');
}

final class NWPatchRequest extends NWRequest {
  const NWPatchRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.body,
    required super.timestamp,
  }) : super(method: 'PATCH');
}

final class NWDeleteRequest extends NWRequest {
  const NWDeleteRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.body,
    required super.timestamp,
  }) : super(method: 'DELETE');
}

final class NWHeadRequest extends NWRequest {
  const NWHeadRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.timestamp,
  }) : super(method: 'HEAD', body: null);
}

final class NWOptionsRequest extends NWRequest {
  const NWOptionsRequest({
    required super.id,
    required super.url,
    required super.headers,
    required super.timestamp,
  }) : super(method: 'OPTIONS', body: null);
}

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
