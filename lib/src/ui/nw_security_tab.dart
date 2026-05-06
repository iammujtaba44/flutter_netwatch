import 'package:flutter/material.dart';

import '../models/nw_security_analysis.dart';
import '../models/nw_transaction.dart';

class NWSecurityTab extends StatelessWidget {
  final NWTransaction transaction;

  const NWSecurityTab({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final analysis = transaction.security;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      children: [
        _RatingHeader(rating: analysis.rating),
        const SizedBox(height: 12),
        _HttpsCard(isHttps: analysis.isHttps),
        const SizedBox(height: 12),
        if (analysis.issues.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
                SizedBox(width: 12),
                Expanded(child: Text('No security issues found')),
              ],
            ),
          )
        else
          for (final issue in analysis.issues) ...[
            _IssueCard(issue: issue),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _RatingHeader extends StatelessWidget {
  final NWSecurityRating rating;

  const _RatingHeader({required this.rating});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (rating) {
      NWSecurityRating.good => (
          Icons.verified_outlined,
          const Color(0xFF4CAF50),
          'GOOD',
        ),
      NWSecurityRating.warning => (
          Icons.warning_amber_outlined,
          const Color(0xFFFFC107),
          'WARNING',
        ),
      NWSecurityRating.critical => (
          Icons.error_outline,
          const Color(0xFFF44336),
          'CRITICAL',
        ),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _HttpsCard extends StatelessWidget {
  final bool isHttps;

  const _HttpsCard({required this.isHttps});

  @override
  Widget build(BuildContext context) {
    final color = isHttps ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final icon = isHttps ? Icons.lock : Icons.lock_open;
    final label =
        isHttps ? 'Secure connection (HTTPS)' : 'Insecure connection (HTTP)';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final NWSecurityIssue issue;

  const _IssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (issue.severity) {
      NWSecuritySeverity.critical => (Icons.error, const Color(0xFFF44336)),
      NWSecuritySeverity.warning => (
          Icons.warning_amber,
          const Color(0xFFFFC107),
        ),
      NWSecuritySeverity.info => (Icons.info_outline, const Color(0xFF2196F3)),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  issue.description,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
