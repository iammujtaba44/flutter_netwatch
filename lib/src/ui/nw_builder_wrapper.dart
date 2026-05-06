import 'package:flutter/material.dart';

import '../core/netwatch_core.dart';
import '../notification/nw_notification_layer.dart';
import 'nw_floating_bubble.dart';

class NWBuilderWrapper extends StatefulWidget {
  final Widget? child;

  const NWBuilderWrapper({super.key, required this.child});

  @override
  State<NWBuilderWrapper> createState() => _NWBuilderWrapperState();
}

class _NWBuilderWrapperState extends State<NWBuilderWrapper> {
  final GlobalKey<OverlayState> _overlayKey = GlobalKey<OverlayState>();

  @override
  void initState() {
    super.initState();
    NetWatchCore.instance.registerOverlay(_overlayKey);
  }

  @override
  Widget build(BuildContext context) {
    final core = NetWatchCore.instance;
    if (!core.isActive) {
      return widget.child ?? const SizedBox.shrink();
    }

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Overlay(
        key: _overlayKey,
        initialEntries: [
          OverlayEntry(
            builder: (_) => Stack(
              children: [
                widget.child ?? const SizedBox.shrink(),
                if (core.config.showNotifications) const NWNotificationLayer(),
                if (core.config.showFloatingBubble) const NWFloatingBubble(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
