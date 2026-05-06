import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/netwatch_core.dart';
import '../exporters/nw_postman_exporter.dart';
import '../models/nw_transaction.dart';
import 'nw_search_bar.dart';
import 'nw_settings_sheet.dart';
import 'nw_transaction_tile.dart';

class NWInspectorScreen extends StatefulWidget {
  final VoidCallback onClose;

  const NWInspectorScreen({super.key, required this.onClose});

  @override
  State<NWInspectorScreen> createState() => _NWInspectorScreenState();
}

class _NWInspectorScreenState extends State<NWInspectorScreen> {
  String _query = '';
  bool _searchOpen = false;
  NWStatusFilter _filter = NWStatusFilter.all;

  @override
  Widget build(BuildContext context) {
    return _RootGuard(
      child: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('NetWatch'),
                actions: [
                  IconButton(
                    icon: Icon(_searchOpen ? Icons.search_off : Icons.search),
                    onPressed: () {
                      setState(() {
                        _searchOpen = !_searchOpen;
                        if (!_searchOpen) _query = '';
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.bar_chart),
                    tooltip: 'Stats',
                    onPressed: () =>
                        NetWatchCore.instance.openStats(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: _openSettings,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _confirmClear,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: StreamBuilder<List<NWTransaction>>(
                    stream: NetWatchCore.instance.transactionStream,
                    initialData: NetWatchCore.instance.storage.getAll(),
                    builder: (context, snapshot) {
                      final all = snapshot.data ?? const <NWTransaction>[];
                      final successCount = all.where(_isSuccess).length;
                      final failureCount = all.where(_isFailure).length;
                      return TabBar(
                        tabs: [
                          _CountTab(
                            label: 'All',
                            count: all.length,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          _CountTab(
                            label: 'Success',
                            count: successCount,
                            color: const Color(0xFF4CAF50),
                          ),
                          _CountTab(
                            label: 'Failure',
                            count: failureCount,
                            color: const Color(0xFFF44336),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              body: Column(
                children: [
                  if (_searchOpen)
                    NWSearchBar(
                      query: _query,
                      onChanged: (v) => setState(() => _query = v),
                      onClose: () => setState(() {
                        _searchOpen = false;
                        _query = '';
                      }),
                    ),
                  _FilterChipsRow(
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: StreamBuilder<List<NWTransaction>>(
                      stream: NetWatchCore.instance.transactionStream,
                      initialData: NetWatchCore.instance.storage.getAll(),
                      builder: (context, snapshot) {
                        final all = snapshot.data ?? const <NWTransaction>[];
                        return TabBarView(
                          children: [
                            _TransactionList(
                              transactions: _applyAllFilters(all),
                              emptyHint: 'No requests yet',
                            ),
                            _TransactionList(
                              transactions: _applyAllFilters(
                                all.where(_isSuccess).toList(),
                              ),
                              emptyHint: 'No successful requests yet',
                            ),
                            _TransactionList(
                              transactions: _applyAllFilters(
                                all.where(_isFailure).toList(),
                              ),
                              emptyHint: 'No failures yet',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  _BottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isSuccess(NWTransaction t) {
    if (t.isPending) return true;
    final code = t.statusCode;
    if (code == null) return false;
    return code >= 200 && code < 400;
  }

  bool _isFailure(NWTransaction t) {
    if (t.isError) return true;
    final code = t.statusCode;
    if (code == null) return false;
    return code >= 400;
  }

  List<NWTransaction> _applyAllFilters(List<NWTransaction> list) {
    return list.where((t) {
      if (!_matchesChipFilter(t)) return false;
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return t.request.url.toString().toLowerCase().contains(q) ||
          t.request.method.toLowerCase().contains(q) ||
          t.statusLabel.toLowerCase().contains(q);
    }).toList();
  }

  bool _matchesChipFilter(NWTransaction t) {
    final code = t.statusCode;
    return switch (_filter) {
      NWStatusFilter.all => true,
      NWStatusFilter.success => code != null && code >= 200 && code < 300,
      NWStatusFilter.redirect => code != null && code >= 300 && code < 400,
      NWStatusFilter.clientError => code != null && code >= 400 && code < 500,
      NWStatusFilter.serverError => code != null && code >= 500,
      NWStatusFilter.slow => t.isSlow,
      NWStatusFilter.errors => t.isError,
    };
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const NWSettingsSheet(),
    );
  }

  void _confirmClear() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all transactions?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              NetWatchCore.instance.clearAll();
              Navigator.of(ctx).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _RootGuard extends StatelessWidget {
  final Widget child;
  const _RootGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: true, child: child);
  }
}

class _CountTab extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountTab({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 22),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  final NWStatusFilter selected;
  final ValueChanged<NWStatusFilter> onSelected;

  const _FilterChipsRow({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final f in NWStatusFilter.values) ...[
            ChoiceChip(
              label: Text(f.label),
              selected: selected == f,
              onSelected: (_) => onSelected(f),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<NWTransaction> transactions;
  final String emptyHint;

  const _TransactionList({
    required this.transactions,
    required this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _EmptyState(hint: emptyHint);
    }
    return ListView.separated(
      itemCount: transactions.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 12, endIndent: 12),
      itemBuilder: (_, i) => NWTransactionTile(
        transaction: transactions[i],
        onTap: () =>
            NetWatchCore.instance.openTransactionDetail(transactions[i]),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18),
              const SizedBox(width: 6),
              const Expanded(child: Text('Mask Sensitive')),
              ValueListenableBuilder<bool>(
                valueListenable: NetWatchCore.instance.maskingEnabled,
                builder: (_, value, __) => Switch(
                  value: value,
                  onChanged: NetWatchCore.instance.setMasking,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: 'Copy all as Postman',
                onPressed: () async {
                  final json = _exportAllPostman();
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
          ),
        ),
      ),
    );
  }

  String _exportAllPostman() {
    final core = NetWatchCore.instance;
    final exporter = NWPostmanExporter(masker: core.masker);
    return exporter.exportCollection(
      core.storage.getAll(),
      masked: core.maskingEnabled.value,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String hint;

  const _EmptyState({required this.hint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_tethering_outlined,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              hint,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Make HTTP calls to populate this list',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
