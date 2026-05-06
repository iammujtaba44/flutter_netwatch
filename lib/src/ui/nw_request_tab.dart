import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/netwatch_core.dart';
import '../exporters/nw_curl_exporter.dart';
import '../masking/nw_masker.dart';
import '../models/nw_transaction.dart';
import '../utils/nw_graphql.dart';
import 'nw_curl_sheet.dart';

class NWRequestTab extends StatelessWidget {
  final NWTransaction transaction;

  const NWRequestTab({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetWatchCore.instance.maskingEnabled,
      builder: (context, masked, _) {
        final request = transaction.request;
        final url = masked
            ? NetWatchCore.instance.masker.maskUrl(request.url)
            : request.url;
        final headers = masked
            ? NetWatchCore.instance.masker.maskHeaders(request.headers)
            : request.headers;
        final body = masked
            ? NetWatchCore.instance.masker.maskBody(request.body)
            : request.body;

        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
          children: [
            _Section(
              title: 'URL',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    url.toString(),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    transaction.createdAt.toIso8601String(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
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
            if (body != null)
              if (NWGraphQL.isGraphQLRequest(body))
                _GraphQLRequestSection(body: body)
              else
                _Section(
                  title: 'Body',
                  trailing: IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () => _copyBody(context, body),
                  ),
                  child: SelectableText(
                    _formatBody(body),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.code),
              label: const Text('Show as cURL'),
              onPressed: () => _openCurl(context),
            ),
          ],
        );
      },
    );
  }

  String _formatBody(Object? body) {
    if (body == null) return '';
    if (body is String) return body;
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  void _copyHeaders(BuildContext context, Map<String, String> headers) {
    final text = headers.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Headers copied'), duration: Duration(seconds: 1)),
    );
  }

  void _copyBody(BuildContext context, Object? body) {
    Clipboard.setData(ClipboardData(text: _formatBody(body)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Body copied'), duration: Duration(seconds: 1)),
    );
  }

  void _openCurl(BuildContext context) {
    final core = NetWatchCore.instance;
    final exporter = NWCurlExporter(masker: core.masker);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NWCurlSheet(
        transaction: transaction,
        exporter: exporter,
      ),
    );
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

class _GraphQLRequestSection extends StatelessWidget {
  final Object body;

  const _GraphQLRequestSection({required this.body});

  @override
  Widget build(BuildContext context) {
    final operation = NWGraphQL.operationName(body);
    final type = NWGraphQL.operationType(body) ?? 'query';
    final query = NWGraphQL.query(body) ?? '';
    final variables = NWGraphQL.variables(body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          title: 'GraphQL ${type.toUpperCase()}',
          trailing: operation == null
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE10098).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    operation,
                    style: const TextStyle(
                      color: Color(0xFFE10098),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
          child: SelectableText(
            query.trim(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        if (variables != null && variables.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'Variables',
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(variables),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
