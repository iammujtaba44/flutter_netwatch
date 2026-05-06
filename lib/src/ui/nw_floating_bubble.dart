import 'package:flutter/material.dart';

import '../core/netwatch_core.dart';
import '../navigation/nw_overlay_router.dart';

class NWFloatingBubble extends StatefulWidget {
  const NWFloatingBubble({super.key});

  @override
  State<NWFloatingBubble> createState() => _NWFloatingBubbleState();
}

class _NWFloatingBubbleState extends State<NWFloatingBubble> {
  late Offset _position;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _position = NetWatchCore.instance.config.initialBubblePosition;
  }

  @override
  Widget build(BuildContext context) {
    if (NWOverlayRouter.hasActive) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    const bubbleSize = 56.0;
    final maxX = size.width - bubbleSize;
    final maxY = size.height - bubbleSize - mediaQuery.padding.bottom;
    final minY = mediaQuery.padding.top;

    if (!_initialized) {
      _position = Offset(
        _position.dx.clamp(0.0, maxX),
        _position.dy.clamp(minY, maxY),
      );
      _initialized = true;
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: ValueListenableBuilder<int>(
        valueListenable: NetWatchCore.instance.unseenCount,
        builder: (context, count, _) {
          return Draggable(
            feedback: _BubbleVisual(
              count: count,
              size: bubbleSize,
              isDragging: true,
            ),
            childWhenDragging: const SizedBox.shrink(),
            onDragEnd: (details) {
              setState(() {
                final dx = details.offset.dx.clamp(0.0, maxX);
                final dy = details.offset.dy.clamp(minY, maxY);
                final snappedX = dx < (size.width / 2) ? 8.0 : maxX - 8.0;
                _position = Offset(snappedX, dy);
              });
            },
            child: GestureDetector(
              onTap: () => NetWatchCore.instance.openInspector(),
              onLongPress: () => _showQuickStats(context),
              child: _BubbleVisual(
                count: count,
                size: bubbleSize,
                isDragging: false,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showQuickStats(BuildContext context) {
    final transactions = NetWatchCore.instance.storage.getAll();
    final total = transactions.length;
    final errors = transactions.where((t) => t.isError).length;
    final slow = transactions.where((t) => t.isSlow).length;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('NetWatch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatRow(label: 'Total', value: '$total requests'),
            _StatRow(label: 'Errors', value: '$errors'),
            _StatRow(label: 'Slow', value: '$slow'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              NetWatchCore.instance.clearAll();
            },
            child: const Text('Clear All'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              NetWatchCore.instance.openInspector();
            },
            child: const Text('Open Inspector'),
          ),
        ],
      ),
    );
  }
}

class _BubbleVisual extends StatelessWidget {
  final int count;
  final double size;
  final bool isDragging;

  const _BubbleVisual({
    required this.count,
    required this.size,
    required this.isDragging,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDragging ? 0.3 : 0.2),
              blurRadius: isDragging ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.visibility_outlined, color: scheme.onPrimary, size: 28),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF44336),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.primary, width: 2),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
