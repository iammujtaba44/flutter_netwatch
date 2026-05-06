import 'package:flutter/material.dart';

import '../models/nw_transaction.dart';
import '../ui/nw_inspector_screen.dart';
import '../ui/nw_stats_screen.dart';
import '../ui/nw_theme.dart';
import '../ui/nw_transaction_detail.dart';

class NWOverlayRouter {
  NWOverlayRouter._();

  static final List<OverlayEntry> _activeEntries = <OverlayEntry>[];

  static bool get hasActive => _activeEntries.isNotEmpty;

  static void openInspector(GlobalKey<OverlayState> overlayKey) {
    final overlay = overlayKey.currentState;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ScreenHost(
        child: NWInspectorScreen(onClose: () => _removeEntry(entry)),
      ),
    );
    _activeEntries.add(entry);
    overlay.insert(entry);
  }

  static void openStats(GlobalKey<OverlayState> overlayKey) {
    final overlay = overlayKey.currentState;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ScreenHost(
        child: NWStatsScreen(onClose: () => _removeEntry(entry)),
      ),
    );
    _activeEntries.add(entry);
    overlay.insert(entry);
  }

  static void openTransactionDetail(
    GlobalKey<OverlayState> overlayKey,
    NWTransaction transaction,
  ) {
    final overlay = overlayKey.currentState;
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ScreenHost(
        child: NWTransactionDetail(
          transaction: transaction,
          onClose: () => _removeEntry(entry),
        ),
      ),
    );
    _activeEntries.add(entry);
    overlay.insert(entry);
  }

  static void closeAll() {
    for (final entry in _activeEntries.toList()) {
      _removeEntry(entry);
    }
  }

  static void _removeEntry(OverlayEntry entry) {
    if (entry.mounted) {
      entry.remove();
    }
    _activeEntries.remove(entry);
  }
}

/// Hosts each NetWatch screen in its own self-contained Theme + Navigator so
/// `showModalBottomSheet`, `showDialog`, and `Navigator.push` work regardless
/// of the surrounding app's theme or navigator.
class _ScreenHost extends StatelessWidget {
  final Widget child;

  const _ScreenHost({required this.child});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    return Theme(
      data: nwTheme(brightness),
      child: HeroControllerScope.none(
        child: Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => child,
          ),
        ),
      ),
    );
  }
}
