import 'package:flutter/material.dart';

import '../core/netwatch_core.dart';
import '../models/nw_transaction.dart';
import 'nw_export_sheet.dart';
import 'nw_request_tab.dart';
import 'nw_response_tab.dart';
import 'nw_security_tab.dart';

class NWTransactionDetail extends StatefulWidget {
  final NWTransaction transaction;
  final VoidCallback onClose;

  const NWTransactionDetail({
    super.key,
    required this.transaction,
    required this.onClose,
  });

  @override
  State<NWTransactionDetail> createState() => _NWTransactionDetailState();
}

class _NWTransactionDetailState extends State<NWTransactionDetail> {
  late NWTransaction _current;

  @override
  void initState() {
    super.initState();
    _current = widget.transaction;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: StreamBuilder<List<NWTransaction>>(
          stream: NetWatchCore.instance.transactionStream,
          initialData: NetWatchCore.instance.storage.getAll(),
          builder: (context, snapshot) {
            final list = snapshot.data ?? const <NWTransaction>[];
            for (final t in list) {
              if (t.id == _current.id) {
                _current = t;
                break;
              }
            }
            return DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: widget.onClose,
                  ),
                  title: Text(
                    '${_current.request.method} ${_current.request.url.path.isEmpty ? '/' : _current.request.url.path}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(72),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _current.statusColor
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _current.statusLabel,
                                  style: TextStyle(
                                    color: _current.statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_current.response != null)
                                Text(
                                  '${_current.response!.duration.inMilliseconds}ms',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              const Spacer(),
                              ValueListenableBuilder<bool>(
                                valueListenable:
                                    NetWatchCore.instance.maskingEnabled,
                                builder: (_, value, __) => Row(
                                  children: [
                                    const Icon(Icons.lock_outline, size: 16),
                                    const SizedBox(width: 4),
                                    Switch(
                                      value: value,
                                      onChanged:
                                          NetWatchCore.instance.setMasking,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const TabBar(
                          tabs: [
                            Tab(text: 'Request'),
                            Tab(text: 'Response'),
                            Tab(text: 'Security'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                body: TabBarView(
                  children: [
                    NWRequestTab(transaction: _current),
                    NWResponseTab(transaction: _current),
                    NWSecurityTab(transaction: _current),
                  ],
                ),
                floatingActionButton: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (NetWatchCore.instance.hasReplayer &&
                        NetWatchCore.instance.canReplay(_current)) ...[
                      FloatingActionButton.extended(
                        heroTag: 'nw_replay',
                        onPressed: () => _replay(context),
                        icon: const Icon(Icons.replay),
                        label: const Text('Replay'),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        foregroundColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 12),
                    ],
                    FloatingActionButton.extended(
                      heroTag: 'nw_export',
                      onPressed: () => _openExport(context),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Export'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openExport(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NWExportSheet(transaction: _current),
    );
  }

  Future<void> _replay(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Replaying request...'),
        duration: Duration(seconds: 1),
      ),
    );
    try {
      await NetWatchCore.instance.replay(_current);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Replay fired — see new transaction in inspector'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Replay failed: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
