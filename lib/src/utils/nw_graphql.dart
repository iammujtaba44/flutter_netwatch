import 'dart:convert';

/// Detects and parses GraphQL operations from request and response bodies.
///
/// GraphQL requests have a recognizable shape:
/// `{ "query": "...", "variables": {...}, "operationName": "..." }`
/// GraphQL responses have:
/// `{ "data": ..., "errors": [...] }`
class NWGraphQL {
  NWGraphQL._();

  /// True if the request body looks like a GraphQL operation.
  static bool isGraphQLRequest(Object? body) {
    final map = _asMap(body);
    if (map == null) return false;
    final query = map['query'];
    return query is String && query.trim().isNotEmpty;
  }

  /// True if the response body looks like a GraphQL response.
  static bool isGraphQLResponse(Object? body) {
    final map = _asMap(body);
    if (map == null) return false;
    return map.containsKey('data') || map.containsKey('errors');
  }

  /// Extracts the operation name from a GraphQL request body, if any.
  ///
  /// Falls back to parsing the first `query`/`mutation`/`subscription`
  /// keyword in the query string.
  static String? operationName(Object? body) {
    final map = _asMap(body);
    if (map == null) return null;
    final explicit = map['operationName'];
    if (explicit is String && explicit.trim().isNotEmpty) {
      return explicit;
    }
    final query = map['query'];
    if (query is! String) return null;
    return _parseOperationFromQuery(query);
  }

  /// Returns the operation type ("query", "mutation", "subscription") if it
  /// can be parsed from the query string.
  static String? operationType(Object? body) {
    final map = _asMap(body);
    if (map == null) return null;
    final query = map['query'];
    if (query is! String) return null;
    final lower = query.trimLeft().toLowerCase();
    if (lower.startsWith('mutation')) return 'mutation';
    if (lower.startsWith('subscription')) return 'subscription';
    if (lower.startsWith('query') || lower.startsWith('{')) return 'query';
    return null;
  }

  /// Returns the GraphQL query string from a request body.
  static String? query(Object? body) {
    final map = _asMap(body);
    final q = map?['query'];
    return q is String ? q : null;
  }

  /// Returns the GraphQL variables map from a request body, or null.
  static Map<String, dynamic>? variables(Object? body) {
    final map = _asMap(body);
    final v = map?['variables'];
    if (v is Map<String, dynamic>) return v;
    return null;
  }

  /// Returns the parsed `data` from a GraphQL response body.
  static Object? responseData(Object? body) {
    final map = _asMap(body);
    return map?['data'];
  }

  /// Returns the `errors` array from a GraphQL response body, or null if none.
  static List<dynamic>? responseErrors(Object? body) {
    final map = _asMap(body);
    final errors = map?['errors'];
    if (errors is List && errors.isNotEmpty) return errors;
    return null;
  }

  /// True if the GraphQL response carries any errors.
  static bool hasErrors(Object? body) => responseErrors(body) != null;

  static Map<String, dynamic>? _asMap(Object? body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    if (body is String && body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  static final RegExp _opNameRegex = RegExp(
    r'^\s*(?:query|mutation|subscription)\s+([A-Za-z_][A-Za-z0-9_]*)',
    multiLine: true,
  );

  static String? _parseOperationFromQuery(String query) {
    final match = _opNameRegex.firstMatch(query);
    return match?.group(1);
  }
}
