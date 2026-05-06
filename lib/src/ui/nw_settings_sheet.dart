import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/netwatch_core.dart';
import '../exporters/nw_postman_exporter.dart';

class NWSettingsSheet extends StatefulWidget {
  const NWSettingsSheet({super.key});

  @override
  State<NWSettingsSheet> createState() => _NWSettingsSheetState();
}

class _NWSettingsSheetState extends State<NWSettingsSheet> {
  late int _budget;

  @override
  void initState() {
    super.initState();
    _budget = NetWatchCore.instance.config.performanceBudgetMs;
  }

  @override
  Widget build(BuildContext context) {
    final core = NetWatchCore.instance;
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
                  'Settings',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: core.maskingEnabled,
              builder: (_, value, __) => SwitchListTile(
                title: const Text('Mask Sensitive Data'),
                value: value,
                onChanged: core.setMasking,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            ListTile(
              title: const Text('Performance Budget'),
              subtitle: Text('${_budget}ms'),
              trailing: SizedBox(
                width: 180,
                child: Slider(
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  value: _budget.toDouble(),
                  label: '${_budget}ms',
                  onChanged: (v) => setState(() => _budget = v.toInt()),
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            Text(
              'SENSITIVE HEADERS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final h in core.config.sensitiveHeaders)
                  Chip(label: Text(h)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'SENSITIVE BODY FIELDS',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final f in core.config.sensitiveBodyFields)
                  Chip(label: Text(f)),
              ],
            ),
            const Divider(height: 32),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear All Transactions'),
              onPressed: () {
                core.clearAll();
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Copy All as Postman Collection'),
              onPressed: () async {
                final exporter = NWPostmanExporter(masker: core.masker);
                final json = exporter.exportCollection(
                  core.storage.getAll(),
                  masked: core.maskingEnabled.value,
                );
                await Clipboard.setData(ClipboardData(text: json));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Postman collection copied'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
