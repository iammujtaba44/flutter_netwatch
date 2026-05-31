import 'package:flutter/widgets.dart';

/// Builds a custom floating bubble.
///
/// - [context] is the overlay build context.
/// - [unseenCount] is the number of requests captured since the inspector was
///   last opened (resets to 0 when it opens).
/// - [openInspector] opens the NetWatch inspector — wire it to your widget's
///   tap handler.
///
/// NetWatch keeps handling drag + edge-snap; the builder only controls the
/// bubble's visual. Return any widget — a [FloatingActionButton], a [Badge],
/// your own design, etc.
typedef NWBubbleBuilder = Widget Function(
  BuildContext context,
  int unseenCount,
  VoidCallback openInspector,
);

/// Configuration passed to [NetWatch.initialize]. Most fields default to
/// sensible values — override only what you need.
class NetWatchConfig {
  final bool enabled;
  final int maxTransactions;

  final bool showFloatingBubble;
  final bool showNotifications;
  final Offset initialBubblePosition;
  final Duration notificationDuration;

  /// Optional custom builder for the floating bubble. When null, NetWatch
  /// renders its built-in bubble (eye icon + unseen-count badge). When set,
  /// your widget replaces the visual but NetWatch still wraps it in the
  /// draggable, edge-snapping container.
  final NWBubbleBuilder? bubbleBuilder;

  final bool maskSensitiveData;
  final List<String> sensitiveHeaders;
  final List<String> sensitiveBodyFields;
  final List<String> sensitiveQueryParams;

  final int performanceBudgetMs;

  const NetWatchConfig({
    this.enabled = true,
    this.maxTransactions = 200,
    this.showFloatingBubble = true,
    this.showNotifications = true,
    this.initialBubblePosition = const Offset(20, 100),
    this.notificationDuration = const Duration(seconds: 3),
    this.bubbleBuilder,
    this.maskSensitiveData = true,
    this.sensitiveHeaders = defaultSensitiveHeaders,
    this.sensitiveBodyFields = defaultSensitiveBodyFields,
    this.sensitiveQueryParams = defaultSensitiveQueryParams,
    this.performanceBudgetMs = 1000,
  });

  NetWatchConfig copyWith({
    bool? enabled,
    int? maxTransactions,
    bool? showFloatingBubble,
    bool? showNotifications,
    Offset? initialBubblePosition,
    Duration? notificationDuration,
    NWBubbleBuilder? bubbleBuilder,
    bool? maskSensitiveData,
    List<String>? sensitiveHeaders,
    List<String>? sensitiveBodyFields,
    List<String>? sensitiveQueryParams,
    int? performanceBudgetMs,
  }) {
    return NetWatchConfig(
      enabled: enabled ?? this.enabled,
      maxTransactions: maxTransactions ?? this.maxTransactions,
      showFloatingBubble: showFloatingBubble ?? this.showFloatingBubble,
      showNotifications: showNotifications ?? this.showNotifications,
      initialBubblePosition:
          initialBubblePosition ?? this.initialBubblePosition,
      notificationDuration: notificationDuration ?? this.notificationDuration,
      bubbleBuilder: bubbleBuilder ?? this.bubbleBuilder,
      maskSensitiveData: maskSensitiveData ?? this.maskSensitiveData,
      sensitiveHeaders: sensitiveHeaders ?? this.sensitiveHeaders,
      sensitiveBodyFields: sensitiveBodyFields ?? this.sensitiveBodyFields,
      sensitiveQueryParams: sensitiveQueryParams ?? this.sensitiveQueryParams,
      performanceBudgetMs: performanceBudgetMs ?? this.performanceBudgetMs,
    );
  }

  static const defaultSensitiveHeaders = <String>[
    'authorization',
    'x-api-key',
    'cookie',
    'set-cookie',
    'x-auth-token',
    'x-access-token',
    'x-refresh-token',
    'proxy-authorization',
    'x-csrf-token',
    'x-session-token',
  ];

  static const defaultSensitiveBodyFields = <String>[
    'password',
    'token',
    'secret',
    'cvv',
    'card_number',
    'cardNumber',
    'pin',
    'ssn',
    'otp',
    'refresh_token',
    'refreshToken',
    'access_token',
    'accessToken',
    'private_key',
    'privateKey',
    'api_key',
    'apiKey',
    'api_secret',
    'apiSecret',
    'credit_card',
    'creditCard',
    'expiry',
    'cvc',
  ];

  static const defaultSensitiveQueryParams = <String>[
    'token',
    'key',
    'password',
    'secret',
    'api_key',
    'apiKey',
    'access_token',
    'auth',
  ];
}
