import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/netwatch_core.dart';
import '../masking/nw_masker.dart';
import '../models/nw_response.dart';
import '../models/nw_transaction.dart';
import '../utils/nw_graphql.dart';

class NWResponseTab extends StatelessWidget {
  final NWTransaction transaction;

  const NWResponseTab({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final response = transaction.response;
    if (response == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 16),
              Text(
                'Awaiting response...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: NetWatchCore.instance.maskingEnabled,
      builder: (context, masked, _) {
        final headers = masked
            ? NetWatchCore.instance.masker.maskHeaders(response.headers)
            : response.headers;
        final budgetMs = NetWatchCore.instance.config.performanceBudgetMs;
        final elapsedMs = response.duration.inMilliseconds;
        final ratio = (elapsedMs / budgetMs).clamp(0.0, 1.0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          children: [
            _StatusCard(
              transaction: transaction,
              elapsedMs: elapsedMs,
              ratio: ratio,
              budgetMs: budgetMs,
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Headers',
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyHeaders(context, headers),
              ),
              child: headers.isEmpty
                  ? const Text('(none)')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in headers.entries)
                          _KeyValueRow(
                            label: entry.key,
                            value: entry.value,
                            highlight: entry.value == nwMaskedValue,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            if (NWGraphQL.isGraphQLResponse(_bodyOf(response))) ...[
              _GraphQLResponseSection(body: _bodyOf(response)),
              const SizedBox(height: 12),
            ],
            _Section(
              title: 'Body',
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () => _copyBody(context, response, masked),
              ),
              child: _BodyView(response: response, masked: masked),
            ),
          ],
        );
      },
    );
  }

  void _copyHeaders(BuildContext context, Map<String, String> headers) {
    final text = headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Headers copied'), duration: Duration(seconds: 1)),
    );
  }

  void _copyBody(BuildContext context, NWResponse response, bool masked) {
    final body = _bodyOf(response);
    final value = masked ? NetWatchCore.instance.masker.maskBody(body) : body;
    Clipboard.setData(ClipboardData(text: _format(value)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Response copied'), duration: Duration(seconds: 1)),
    );
  }

  Object? _bodyOf(NWResponse response) => switch (response) {
        NWSuccessResponse r => r.body,
        NWRedirectResponse r => 'Redirect → ${r.location}',
        NWClientErrorResponse r => r.body,
        NWServerErrorResponse r => r.body,
        NWNetworkErrorResponse r => r.errorMessage,
      };

  String _format(Object? body) {
    if (body == null) return '';
    if (body is String) return body;
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }
}

class _StatusCard extends StatelessWidget {
  final NWTransaction transaction;
  final int elapsedMs;
  final double ratio;
  final int budgetMs;

  const _StatusCard({
    required this.transaction,
    required this.elapsedMs,
    required this.ratio,
    required this.budgetMs,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                transaction.statusLabel,
                style: TextStyle(
                  color: transaction.statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _statusText(transaction.statusCode),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 16),
              const SizedBox(width: 4),
              Text('${elapsedMs}ms'),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ratio >= 1.0
                          ? const Color(0xFFFFC107)
                          : const Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${budgetMs}ms',
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (transaction.response?.contentLength != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.data_object, size: 16),
                const SizedBox(width: 4),
                Text(_formatBytes(transaction.response!.contentLength!)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(int? code) {
    if (code == null) return '';
    if (code >= 200 && code < 300) return 'OK';
    if (code >= 300 && code < 400) return 'Redirect';
    if (code == 400) return 'Bad Request';
    if (code == 401) return 'Unauthorized';
    if (code == 403) return 'Forbidden';
    if (code == 404) return 'Not Found';
    if (code == 408) return 'Request Timeout';
    if (code == 429) return 'Too Many Requests';
    if (code == 500) return 'Internal Server Error';
    if (code == 502) return 'Bad Gateway';
    if (code == 503) return 'Service Unavailable';
    if (code == 504) return 'Gateway Timeout';
    return '';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}

class _BodyView extends StatefulWidget {
  final NWResponse response;
  final bool masked;

  const _BodyView({required this.response, required this.masked});

  @override
  State<_BodyView> createState() => _BodyViewState();
}

class _BodyViewState extends State<_BodyView> {
  bool _formatted = true;

  @override
  Widget build(BuildContext context) {
    final body = _bodyOf(widget.response);
    final masked =
        widget.masked ? NetWatchCore.instance.masker.maskBody(body) : body;
    final text = _formatted ? _format(masked) : masked?.toString() ?? '';

    if (widget.response is NWNetworkErrorResponse) {
      final r = widget.response as NWNetworkErrorResponse;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF44336).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF44336)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                r.errorMessage,
                style: const TextStyle(color: Color(0xFFF44336)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              label: const Text('Raw'),
              selected: !_formatted,
              onSelected: (_) => setState(() => _formatted = false),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Formatted'),
              selected: _formatted,
              onSelected: (_) => setState(() => _formatted = true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SelectableText(
          text.isEmpty ? '(empty)' : text,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }

  Object? _bodyOf(NWResponse response) => switch (response) {
        NWSuccessResponse r => r.body,
        NWRedirectResponse r => 'Redirect → ${r.location}',
        NWClientErrorResponse r => r.body,
        NWServerErrorResponse r => r.body,
        NWNetworkErrorResponse r => r.errorMessage,
      };

  String _format(Object? body) {
    if (body == null) return '';
    if (body is String) {
      try {
        final decoded = jsonDecode(body);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return body;
      }
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _KeyValueRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          SelectableText(
            '$label: ',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SelectableText(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: highlight ? const Color(0xFFFF9800) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraphQLResponseSection extends StatelessWidget {
  final Object? body;

  const _GraphQLResponseSection({required this.body});

  @override
  Widget build(BuildContext context) {
    final data = NWGraphQL.responseData(body);
    final errors = NWGraphQL.responseErrors(body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errors != null)
          _Section(
            title: 'GraphQL Errors',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${errors.length}',
                style: const TextStyle(
                  color: Color(0xFFF44336),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(errors),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        if (errors != null && data != null) const SizedBox(height: 12),
        if (data != null)
          _Section(
            title: 'GraphQL Data',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE10098).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'GraphQL',
                style: TextStyle(
                  color: Color(0xFFE10098),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(data),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
      ],
    );
  }
}
