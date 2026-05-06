import 'nw_request.dart';

enum NWSecurityRating { good, warning, critical }

enum NWSecuritySeverity { info, warning, critical }

class NWSecurityIssue {
  final String title;
  final String description;
  final NWSecuritySeverity severity;

  const NWSecurityIssue({
    required this.title,
    required this.description,
    required this.severity,
  });
}

/// Snapshot of the security posture of a single request — HTTPS usage,
/// presence of hardening headers, and any flagged [issues].
class NWSecurityAnalysis {
  final bool isHttps;
  final List<NWSecurityIssue> issues;
  final NWSecurityRating rating;

  const NWSecurityAnalysis({
    required this.isHttps,
    required this.issues,
    required this.rating,
  });

  factory NWSecurityAnalysis.analyze(NWRequest request) {
    final issues = <NWSecurityIssue>[];
    final lowerCaseHeaders = <String, String>{
      for (final entry in request.headers.entries)
        entry.key.toLowerCase(): entry.value,
    };

    if (request.url.scheme != 'https') {
      issues.add(const NWSecurityIssue(
        title: 'Insecure connection',
        description: 'Request uses HTTP instead of HTTPS. '
            'Data is transmitted unencrypted.',
        severity: NWSecuritySeverity.critical,
      ));
    }

    if (!lowerCaseHeaders.containsKey('strict-transport-security')) {
      issues.add(const NWSecurityIssue(
        title: 'Missing HSTS header',
        description: 'Add Strict-Transport-Security header to enforce HTTPS.',
        severity: NWSecuritySeverity.warning,
      ));
    }

    if (!lowerCaseHeaders.containsKey('x-content-type-options')) {
      issues.add(const NWSecurityIssue(
        title: 'Missing X-Content-Type-Options',
        description:
            'Add X-Content-Type-Options: nosniff to prevent MIME sniffing.',
        severity: NWSecuritySeverity.warning,
      ));
    }

    final queryParams = request.url.queryParameters;
    const sensitiveParams = [
      'token',
      'key',
      'password',
      'secret',
      'api_key',
      'apiKey',
      'access_token',
      'auth',
    ];
    for (final param in sensitiveParams) {
      if (queryParams.containsKey(param)) {
        issues.add(NWSecurityIssue(
          title: 'Sensitive data in URL',
          description: 'Found "$param" in query parameters. '
              'Sensitive data should be in headers or body.',
          severity: NWSecuritySeverity.critical,
        ));
      }
    }

    final auth = lowerCaseHeaders['authorization'];
    if (auth != null && auth.toLowerCase().startsWith('basic ')) {
      issues.add(const NWSecurityIssue(
        title: 'Basic auth detected',
        description:
            'Basic auth encodes credentials in Base64 (not encrypted). '
            'Consider using Bearer tokens.',
        severity: NWSecuritySeverity.warning,
      ));
    }

    if (!lowerCaseHeaders.containsKey('content-security-policy')) {
      issues.add(const NWSecurityIssue(
        title: 'Missing Content-Security-Policy',
        description: 'CSP header helps prevent XSS attacks.',
        severity: NWSecuritySeverity.info,
      ));
    }

    return NWSecurityAnalysis(
      isHttps: request.url.scheme == 'https',
      issues: issues,
      rating: _computeRating(issues),
    );
  }

  static NWSecurityRating _computeRating(List<NWSecurityIssue> issues) {
    if (issues.any((i) => i.severity == NWSecuritySeverity.critical)) {
      return NWSecurityRating.critical;
    }
    if (issues.any((i) => i.severity == NWSecuritySeverity.warning)) {
      return NWSecurityRating.warning;
    }
    return NWSecurityRating.good;
  }
}
