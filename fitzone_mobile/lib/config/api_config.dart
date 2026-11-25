import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _prefKey = 'fitzone_api_base_url';

  static const String _envBaseUrl = String.fromEnvironment('FITZONE_API_URL');

  /// URL por defecto inteligente según plataforma:
  /// - Si se compila con --dart-define=FITZONE_API_URL=..., usa esa URL (ej. IP Wi-Fi o Render).
  /// - Emulador Android: 10.0.2.2 apunta al localhost del PC host.
  /// - Web / Desktop / iOS Simulator: localhost:8080.
  static String get defaultBaseUrl {
    if (_envBaseUrl.trim().isNotEmpty) {
      return _normalize(_envBaseUrl);
    }
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static String _currentBaseUrl = defaultBaseUrl;
  static String get baseUrl => _currentBaseUrl;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.trim().isNotEmpty) {
      _currentBaseUrl = _normalize(saved);
    } else {
      _currentBaseUrl = defaultBaseUrl;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    final normalized = _normalize(url);
    _currentBaseUrl = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, normalized);
  }

  static Future<void> resetToDefault() async {
    _currentBaseUrl = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  static String _normalize(String raw) {
    var trimmed = raw.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    return trimmed;
  }
}
