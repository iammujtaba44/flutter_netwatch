import 'package:flutter/material.dart';
import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    NetWatch.initialize(config: const NetWatchConfig());
    NetWatchCore.instance.clearAll();
  });

  testWidgets('NetWatch.builder wraps app in own Overlay', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: NetWatch.builder,
        home: const Scaffold(body: Text('app body')),
      ),
    );
    expect(find.text('app body'), findsOneWidget);
  });

  testWidgets('Inspector opens via overlay without pushing route',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        builder: NetWatch.builder,
        home: const Scaffold(body: Text('home')),
      ),
    );
    await tester.pump();

    expect(find.text('home'), findsOneWidget);

    NetWatchCore.instance.openInspector();
    await tester.pumpAndSettle();

    expect(find.text('NetWatch'), findsOneWidget);
    expect(navKey.currentState!.canPop(), false);
  });

  testWidgets('Custom navigatorKey is preserved', (tester) async {
    final myKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: myKey,
        navigatorObservers: [NetWatch.observer],
        builder: NetWatch.builder,
        home: const Scaffold(body: Text('A')),
      ),
    );
    await tester.pump();
    expect(myKey.currentState, isNotNull);
  });
}
