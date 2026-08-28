import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Central place for environment-dependent config. Android emulators can't
/// reach the host machine via `localhost`, so we route through the special
/// `10.0.2.2` alias there; every other target (web, iOS simulator, desktop)
/// talks to `localhost` directly.
class AppConfig {
  static const int serverPort = 3000;

  static String get _defaultHost {
    final isAndroidEmulator = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroidEmulator ? '10.0.2.2' : 'localhost';
  }

  static String get serverBaseUrl {
    const overrideUrl = String.fromEnvironment('DURAK_SERVER_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;
    return 'http://$_defaultHost:$serverPort';
  }

  static bool get isWeb => kIsWeb;
}
