import 'package:flutter/material.dart';

/// Wraps bottom-sheet content in a local `ScaffoldMessenger + Scaffold` so
/// `ScaffoldMessenger.of(context).showSnackBar(...)` displays the snackbar
/// inside the sheet rather than on the (now-covered) parent inspector.
///
/// Use the [BuildContext] passed to [builder] for any
/// `ScaffoldMessenger.of(context)` calls.
class NWSheetShell extends StatelessWidget {
  final WidgetBuilder builder;

  const NWSheetShell({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(builder: builder),
      ),
    );
  }
}
