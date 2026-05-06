import 'package:flutter/material.dart';

import '../core/netwatch_core.dart';
import '../models/nw_transaction.dart';

class NWTransactionTile extends StatelessWidget {
  final NWTransaction transaction;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const NWTransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final method = transaction.request.method;
    final url = transaction.request.url;
    final durationMs = transaction.response?.duration.inMilliseconds;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: const Color(0xFFF44336),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        if (onDelete != null) {
          onDelete!();
        } else {
          NetWatchCore.instance.removeTransaction(transaction.id);
        }
      },
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: transaction.statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _MethodBadge(method: method),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              url.path.isEmpty ? '/' : url.path,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (transaction.isPending)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: transaction.statusColor
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                transaction.statusLabel,
                                style: TextStyle(
                                  color: transaction.statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (durationMs != null) ...[
                            const SizedBox(width: 8),
                            if (transaction.isSlow) ...[
                              const Icon(
                                Icons.bolt,
                                size: 14,
                                color: Color(0xFFFFC107),
                              ),
                              const SizedBox(width: 2),
                            ],
                            Text(
                              '${durationMs}ms',
                              style: TextStyle(
                                color: transaction.isSlow
                                    ? const Color(0xFFFFC107)
                                    : scheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              url.host,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(transaction.createdAt),
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Copy as cURL'),
              onTap: () {
                Navigator.of(ctx).pop();
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(ctx).pop();
                onTap();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(ctx).pop();
                NetWatchCore.instance.removeTransaction(transaction.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;

  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _colorFor(String method) {
    return switch (method.toUpperCase()) {
      'GET' => const Color(0xFF4CAF50),
      'POST' => const Color(0xFF2196F3),
      'PUT' => const Color(0xFFFF9800),
      'PATCH' => const Color(0xFF9C27B0),
      'DELETE' => const Color(0xFFF44336),
      _ => const Color(0xFF9E9E9E),
    };
  }
}
