import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, Map<String, dynamic>>((ref) {
  return AppSettingsNotifier();
});

class AppSettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  AppSettingsNotifier() : super({'autoUpdateLibrary': false}) {
    _load();
  }

  Future<void> _load() async {
    final str = await StorageService.read('app_settings');
    if (str != null) {
      state = Map<String, dynamic>.from(jsonDecode(str));
    }
  }

  Future<void> toggleAutoUpdate(bool value) async {
    final newState = {...state, 'autoUpdateLibrary': value};
    state = newState;
    await StorageService.write('app_settings', jsonEncode(newState));
  }
}
