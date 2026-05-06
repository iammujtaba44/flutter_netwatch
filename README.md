# flutter_netwatch

A production-grade Flutter HTTP inspector with sensitive data masking, cURL export, Postman export, security analysis, floating bubble UI, and QA-ready notifications.

[![Author](https://img.shields.io/badge/Author-Mujtaba-1F6FEB?style=for-the-badge&logo=safari&logoColor=white)](https://www.mujtaba.cc/)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/immujtaba9h)

## Demo

<p align="center">
  <img src="assets/demo.gif" alt="flutter_netwatch demo" width="320" />
</p>

The recording shows a real Flutter app running with `flutter_netwatch` wired in:

1. The app fires HTTP requests through Dio.
2. Each request shows up live in the floating bubble (top-right) with an unseen-count badge.
3. Tap the bubble to open the full-screen inspector — list filters by 2xx / 3xx / 4xx / 5xx / slow / errors.
4. Tap a transaction to inspect URL, headers, body, and security analysis.
5. Toggle the lock icon to mask sensitive headers / fields / query params live.
6. FAB **Export** opens cURL, Postman, and plain-text export options.

> Full-quality MP4: [assets/demo.mp4](assets/demo.mp4)

- **Zero navigator conflicts** — works with any `MaterialApp` setup
- **Auto-disabled in release builds** via `kReleaseMode`
- **Sealed classes** throughout — exhaustive pattern matching
- **No native dependencies** — pure Flutter Overlay
- Supports **Dio**, **http**, and **Chopper**

## Install

```yaml
dependencies:
  flutter_netwatch: ^0.1.0
```

## Setup

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_netwatch/flutter_netwatch.dart';
import 'package:dio/dio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  NetWatch.initialize(
    config: NetWatchConfig(
      enabled: !kReleaseMode,
      maskSensitiveData: true,
      showFloatingBubble: true,
      showNotifications: true,
      maxTransactions: 200,
      performanceBudgetMs: 1000,
    ),
  );

  final dio = Dio();
  dio.interceptors.add(NetWatch.dioInterceptor);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: NetWatch.builder, // only required change
      home: HomeScreen(),
    );
  }
}
```

## Three setup scenarios — all work without conflict

### A) No existing navigator key

```dart
MaterialApp(
  builder: NetWatch.builder,
  home: HomeScreen(),
)
```

### B) Existing key + observer

```dart
MaterialApp(
  navigatorKey: myKey,
  navigatorObservers: [NetWatch.observer],
  builder: NetWatch.builder,
)
```

### C) Existing key only — zero observer

```dart
MaterialApp(
  navigatorKey: myKey,
  builder: NetWatch.builder,
)
```

NetWatch never pushes routes onto your navigator. The inspector opens as an `OverlayEntry` over the app inside its own `Overlay`.

## Other clients

### http

```dart
import 'package:http/http.dart' as http;

final client = NetWatch.httpClient(http.Client());
await client.get(Uri.parse('https://api.example.com/users'));
```

### Chopper

```dart
final chopperClient = ChopperClient(
  interceptors: [NetWatch.chopperInterceptor],
);
```

## Features

### In-app inspector

Tap the floating bubble (or call `NetWatch.open()`) to launch the full-screen inspector. Filter by status (2xx, 3xx, 4xx, 5xx, slow, errors), search by URL/method/status, and tap any row for full request/response/security details.

### Sensitive data masking

Headers like `Authorization`, `Cookie`, `X-API-Key`, body fields like `password`, `token`, `secret`, and URL query params like `?token=...` are masked automatically. Toggle masking on/off live in the UI — affects every export.

```dart
NetWatch.initialize(
  config: NetWatchConfig(
    sensitiveHeaders: [
      ...NetWatchConfig.defaultSensitiveHeaders,
      'x-my-custom-token',
    ],
    sensitiveBodyFields: [
      ...NetWatchConfig.defaultSensitiveBodyFields,
      'pin_code',
    ],
  ),
);
```

### Exporters

- **cURL** — copy/share any request as a runnable cURL command.
- **Postman** — export single request or full collection (Postman Collection v2.1).
- **Plain text** — share complete request/response details.

### Security analysis

Each captured request is checked for:
- HTTPS usage
- HSTS / X-Content-Type-Options / CSP headers
- Sensitive data in URL query params
- Basic auth scheme usage

A rating (`good` / `warning` / `critical`) is computed per request.

### Performance budget

Requests slower than the configured budget (`performanceBudgetMs`, default 1000ms) are flagged as `NWStatusSlow`.

## Programmatic API

```dart
NetWatch.open();              // open inspector
NetWatch.clear();             // clear captured transactions
NetWatch.transactions;        // List<NWTransaction>
NetWatch.transactionStream;   // Stream<List<NWTransaction>>
NetWatch.isActive;            // false in release builds
```

## Auto-disable in release

NetWatch checks `kReleaseMode` at initialization and at every interceptor entry point. In release builds:
- `NetWatch.builder` returns the child unchanged.
- Interceptors are no-ops — they call `handler.next()` immediately.
- The core singleton stays empty.

You can leave `NetWatch.initialize()` and the interceptors in production code with zero overhead.

## Author

Built by **[Mujtaba](https://www.mujtaba.cc/)** — software engineer working on Flutter, AI, and developer tooling.

If `flutter_netwatch` saves you debugging time, consider supporting:

<a href="https://buymeacoffee.com/immujtaba9h" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="50" />
</a>

## License

MIT
