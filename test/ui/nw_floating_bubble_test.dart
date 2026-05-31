import 'package:flutter/material.dart';
import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    // Restore a clean default config between tests.
    NetWatch.initialize(config: const NetWatchConfig());
    NetWatchCore.instance.clearAll();
  });

  testWidgets('renders the built-in bubble when no bubbleBuilder is set',
      (tester) async {
    NetWatch.initialize(config: const NetWatchConfig());
    NetWatchCore.instance.clearAll();

    await tester.pumpWidget(
      MaterialApp(
        builder: NetWatch.builder,
        home: const Scaffold(body: Text('app')),
      ),
    );
    await tester.pump();

    // The default visual uses the visibility icon.
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('renders a custom bubble when bubbleBuilder is provided',
      (tester) async {
    NetWatch.initialize(
      config: NetWatchConfig(
        bubbleBuilder: (context, unseenCount, openInspector) {
          return FloatingActionButton(
            onPressed: openInspector,
            child: const Icon(Icons.wifi_tethering),
          );
        },
      ),
    );
    NetWatchCore.instance.clearAll();

    await tester.pumpWidget(
      MaterialApp(
        builder: NetWatch.builder,
        home: const Scaffold(body: Text('app')),
      ),
    );
    await tester.pump();

    // Custom visual is shown; built-in one is not.
    expect(find.byIcon(Icons.wifi_tethering), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
  });

  testWidgets('custom bubble receives the live unseen count', (tester) async {
    NetWatch.initialize(
      config: NetWatchConfig(
        showNotifications: false,
        bubbleBuilder: (context, unseenCount, openInspector) {
          return Text('unseen=$unseenCount', textDirection: TextDirection.ltr);
        },
      ),
    );
    NetWatchCore.instance.clearAll();

    await tester.pumpWidget(
      MaterialApp(
        builder: NetWatch.builder,
        home: const Scaffold(body: Text('app')),
      ),
    );
    await tester.pump();
    expect(find.text('unseen=0'), findsOneWidget);

    // Capturing a transaction bumps the unseen count; the bubble rebuilds.
    final req = NWGetRequest(
      id: '1',
      url: Uri.parse('https://example.com/x'),
      headers: const {},
      timestamp: DateTime(2024),
    );
    NetWatchCore.instance.addTransaction(
      NWTransaction(
        id: '1',
        request: req,
        response: null,
        status: const NWStatusPending(),
        security: NWSecurityAnalysis.analyze(req),
        createdAt: DateTime(2024),
      ),
    );
    await tester.pump();
    expect(find.text('unseen=1'), findsOneWidget);
  });

  testWidgets('tapping a custom bubble opens the inspector', (tester) async {
    NetWatch.initialize(
      config: NetWatchConfig(
        showNotifications: false,
        bubbleBuilder: (context, unseenCount, openInspector) {
          return FloatingActionButton(
            onPressed: openInspector,
            child: const Icon(Icons.wifi_tethering),
          );
        },
      ),
    );
    NetWatchCore.instance.clearAll();

    await tester.pumpWidget(
      MaterialApp(
        builder: NetWatch.builder,
        home: const Scaffold(body: Text('app')),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.wifi_tethering));
    await tester.pumpAndSettle();

    // Inspector opened over the app.
    expect(find.text('NetWatch'), findsOneWidget);
  });

  test('NetWatchConfig.copyWith carries bubbleBuilder through', () {
    Widget builder(BuildContext c, int n, VoidCallback open) =>
        const SizedBox.shrink();
    final config = NetWatchConfig(bubbleBuilder: builder);
    final copy = config.copyWith(maskSensitiveData: false);
    expect(copy.bubbleBuilder, same(builder));
    expect(copy.maskSensitiveData, false);
  });
}
