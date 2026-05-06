import 'package:flutter/widgets.dart';

/// Configuration passed to [NetWatch.initialize]. Most fields default to
/// sensible values — override only what you need.
class NetWatchConfig {
  final bool enabled;
  final int maxTransactions;

  final bool showFloatingBubble;
  final bool showNotifications;
  final Offset initialBubblePosition;
  final Duration notificationDuration;

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
