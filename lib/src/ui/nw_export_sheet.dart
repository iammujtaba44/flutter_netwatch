import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/netwatch_core.dart';
import '../exporters/nw_curl_exporter.dart';
import '../exporters/nw_postman_exporter.dart';
import '../exporters/nw_share_exporter.dart';
import '../models/nw_response.dart';
import '../models/nw_transaction.dart';

class NWExportSheet extends StatelessWidget {
  final NWTransaction transaction;

  const NWExportSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final core = NetWatchCore.instance;
    final curl = NWCurlExporter(masker: core.masker);
    final postman = NWPostmanExporter(masker: core.masker);
    final shareExporter = NWShareExporter(masker: core.masker);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Text(
                  'Export Options',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 16),
                const SizedBox(width: 4),
                const Expanded(child: Text('Mask Sensitive')),
                ValueListenableBuilder<bool>(
                  valueListenable: core.maskingEnabled,
                  builder: (_, value, __) => Switch(
                    value: value,
                    onChanged: core.setMasking,
                  ),
                ),
              ],
            ),
            const Divider(),
            const _SectionHeader(title: 'Copy to Clipboard'),
            _ActionTile(
              icon: Icons.code,
              label: 'Copy as cURL',
              onTap: () => _copy(
                context,
                curl.export(transaction, masked: core.maskingEnabled.value),
                'cURL copied',
              ),
            ),
            _ActionTile(
              icon: Icons.send_outlined,
              label: 'Copy as Postman Request',
              onTap: () => _copy(
                context,
                postman.exportSingle(
                  transaction,
                  masked: core.maskingEnabled.value,
                ),
                'Postman request copied',
              ),
            ),
            _ActionTile(
              icon: Icons.text_snippet_outlined,
              label: 'Copy as Plain Text',
              onTap: () => _copy(
                context,
                shareExporter.exportAsText(
                  transaction,
                  masked: core.maskingEnabled.value,
                ),
                'Plain text copied',
              ),
            ),
            _ActionTile(
              icon: Icons.data_object,
              label: 'Copy Response JSON',
              onTap: () => _copyResponse(context),
            ),
            const Divider(),
            const _SectionHeader(title: 'Share'),
            _ActionTile(
              icon: Icons.share_outlined,
              label: 'Share as cURL',
              onTap: () async {
                final value = curl.export(
                  transaction,
                  masked: core.maskingEnabled.value,
                );
                await Share.share(value);
              },
            ),
            _ActionTile(
              icon: Icons.share_outlined,
              label: 'Share as Plain Text',
              onTap: () async {
                final value = shareExporter.exportAsText(
                  transaction,
                  masked: core.maskingEnabled.value,
                );
                await Share.share(value);
              },
            ),
            _ActionTile(
              icon: Icons.share_outlined,
              label: 'Share as JSON',
              onTap: () async {
                final value = postman.exportSingle(
                  transaction,
                  masked: core.maskingEnabled.value,
                );
                await Share.share(value);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _copy(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _copyResponse(BuildContext context) async {
    final response = transaction.response;
    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No response yet')),
      );
      return;
    }
    final body = switch (response) {
      NWSuccessResponse r => r.body,
      NWClientErrorResponse r => r.body,
      NWServerErrorResponse r => r.body,
      NWRedirectResponse r => 'Redirect → ${r.location}',
      NWNetworkErrorResponse r => r.errorMessage,
    };
    final masked = NetWatchCore.instance.maskingEnabled.value
        ? NetWatchCore.instance.masker.maskBody(body)
        : body;
    final text = masked is String
        ? masked
        : (masked == null
            ? ''
            : const JsonEncoder.withIndent('  ').convert(masked));
    await _copy(context, text, 'Response copied');
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
