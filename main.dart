import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final env = await _loadEnv();
  final prefs = await SharedPreferences.getInstance();

  final config = AppConfig(
    operador: env['OPERADOR'] ?? 'A. Mosquera',
    apiBaseUrl: env['API_BASE_URL'] ?? '',
  );

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        prefsProvider.overrideWithValue(prefs),
      ],
      child: const DocIntelApp(),
    ),
  );
}

/// Carga `.env` (declarado como asset) sin dependencias externas.
Future<Map<String, String>> _loadEnv() async {
  try {
    final raw = await rootBundle.loadString('.env');
    final map = <String, String>{};
    for (final line in raw.split('\n')) {
      final l = line.trim();
      if (l.isEmpty || l.startsWith('#') || !l.contains('=')) continue;
      final i = l.indexOf('=');
      map[l.substring(0, i).trim()] = l.substring(i + 1).trim();
    }
    return map;
  } catch (_) {
    return {};
  }
}
