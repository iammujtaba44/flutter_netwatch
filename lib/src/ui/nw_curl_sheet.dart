import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/netwatch_core.dart';
import '../exporters/nw_curl_exporter.dart';
import '../models/nw_transaction.dart';
import 'nw_sheet_shell.dart';

class NWCurlSheet extends StatelessWidget {
  final NWTransaction transaction;
  final NWCurlExporter exporter;

  const NWCurlSheet({
    super.key,
    required this.transaction,
    required this.exporter,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => NWSheetShell(
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Copy as cURL',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
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
                    valueListenable: NetWatchCore.instance.maskingEnabled,
                    builder: (_, value, __) => Switch(
                      value: value,
                      onChanged: NetWatchCore.instance.setMasking,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: NetWatchCore.instance.maskingEnabled,
                  builder: (_, value, __) {
                    final curl = exporter.export(transaction, masked: value);
                    return _CurlBlock(curl: curl, controller: controller);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      onPressed: () async {
                        final curl = exporter.export(
                          transaction,
                          masked: NetWatchCore.instance.maskingEnabled.value,
                        );
                        await Clipboard.setData(ClipboardData(text: curl));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('cURL copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      onPressed: () async {
                        final curl = exporter.export(
                          transaction,
                          masked: NetWatchCore.instance.maskingEnabled.value,
                        );
                        await Share.share(curl);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurlBlock extends StatelessWidget {
  final String curl;
  final ScrollController controller;

  const _CurlBlock({required this.curl, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        controller: controller,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            curl,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ),
    );
  }
}
