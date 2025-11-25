import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum AudioQuality { high, medium, low }

class SettingsNotifier extends StateNotifier<AudioQuality> {
  SettingsNotifier() : super(AudioQuality.high) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final box = await Hive.openBox('settings');
    final qualityIndex = box.get('audioQuality', defaultValue: 0);
    state = AudioQuality.values[qualityIndex];
  }

  Future<void> setAudioQuality(AudioQuality quality) async {
    state = quality;
    final box = await Hive.openBox('settings');
    await box.put('audioQuality', quality.index);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AudioQuality>((ref) {
  return SettingsNotifier();
});
