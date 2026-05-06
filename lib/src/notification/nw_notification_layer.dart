import 'package:flutter/material.dart';

import '../core/netwatch_core.dart';
import '../models/nw_transaction.dart';

class NWNotificationLayer extends StatefulWidget {
  const NWNotificationLayer({super.key});

  static final List<_NotificationData> _activeNotifications =
      <_NotificationData>[];
  static final List<_NWNotificationLayerState> _states =
      <_NWNotificationLayerState>[];
  static const int _maxStacked = 3;

  static void show(
    GlobalKey<OverlayState> overlayKey,
    NWTransaction transaction,
  ) {
    for (final existing in _activeNotifications) {
      if (!existing.dismissed && existing.transaction.id == transaction.id) {
        existing.transaction = transaction;
        for (final state in _states.toList()) {
          if (state.mounted) state.refresh();
        }
        return;
      }
    }

    final data = _NotificationData(transaction: transaction);
    _activeNotifications.add(data);

    while (
        _activeNotifications.where((d) => !d.dismissed).length > _maxStacked) {
      final oldest = _activeNotifications.firstWhere((d) => !d.dismissed);
      oldest.dismissed = true;
    }

    for (final state in _states.toList()) {
      if (state.mounted) state.refresh();
    }
  }

  @override
  State<NWNotificationLayer> createState() => _NWNotificationLayerState();
}

class _NWNotificationLayerState extends State<NWNotificationLayer> {
  @override
  void initState() {
    super.initState();
    NWNotificationLayer._states.add(this);
  }

  @override
  void dispose() {
    NWNotificationLayer._states.remove(this);
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final notifications = NWNotificationLayer._activeNotifications
        .where((d) => !d.dismissed)
        .toList();

    return Positioned(
      top: mediaQuery.padding.top + 8,
      left: 8,
      right: 8,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final data in notifications)
              _NWNotificationBanner(
                key: ValueKey(data.transaction.id),
                data: data,
                onDismiss: () {
                  data.dismissed = true;
                  refresh();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationData {
  NWTransaction transaction;
  bool dismissed = false;
  _NotificationData({required this.transaction});
}

class _NWNotificationBanner extends StatefulWidget {
  final _NotificationData data;
  final VoidCallback onDismiss;

  const _NWNotificationBanner({
    super.key,
    required this.data,
    required this.onDismiss,
  });

  @override
  State<_NWNotificationBanner> createState() => _NWNotificationBannerState();
}

class _NWNotificationBannerState extends State<_NWNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    Future.delayed(NetWatchCore.instance.config.notificationDuration, () {
      if (mounted && !widget.data.dismissed) {
        _dismiss();
      }
    });
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.data.transaction;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        color: transaction.statusColor,
                      ),
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
                                  _MethodBadge(
                                      method: transaction.request.method),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      transaction.request.url.path.isEmpty
                                          ? '/'
                                          : transaction.request.url.path,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      transaction.request.url.host,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (transaction.response != null)
                                    Text(
                                      '${transaction.response!.duration.inMilliseconds}ms',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      _dismiss();
                                      NetWatchCore.instance
                                          .openTransactionDetail(transaction);
                                    },
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'View →',
                                      style: TextStyle(fontSize: 12),
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
            ),
          ),
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
