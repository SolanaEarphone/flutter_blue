// Copyright 2024, SolanaEarphone.
// All rights reserved.

import 'dart:async';

import '../models/headphone_settings.dart';

/// Service for managing audio profiles and settings
class AudioProfileService {
  static final AudioProfileService _instance = AudioProfileService._internal();
  factory AudioProfileService() => _instance;
  AudioProfileService._internal();

  final _settingsController = StreamController<HeadphoneSettings>.broadcast();
  Stream<HeadphoneSettings> get settingsStream => _settingsController.stream;

  HeadphoneSettings _currentSettings = const HeadphoneSettings();
  HeadphoneSettings get currentSettings => _currentSettings;

  /// Predefined audio profiles
  static const Map<String, HeadphoneSettings> _presets = {
    'Balanced': HeadphoneSettings(
      volume: 50,
      bassBoost: 0,
      treble: 50,
      noiseCancellation: NoiseCancellationMode.on,
      ambientSound: 0,
      spatialAudio: false,
    ),
    'Bass Boost': HeadphoneSettings(
      volume: 60,
      bassBoost: 80,
      treble: 40,
      noiseCancellation: NoiseCancellationMode.on,
      ambientSound: 0,
      spatialAudio: false,
    ),
    'Vocal Focus': HeadphoneSettings(
      volume: 55,
      bassBoost: 20,
      treble: 70,
      noiseCancellation: NoiseCancellationMode.on,
      ambientSound: 0,
      spatialAudio: false,
    ),
    'Ambient Aware': HeadphoneSettings(
      volume: 50,
      bassBoost: 0,
      treble: 50,
      noiseCancellation: NoiseCancellationMode.transparency,
      ambientSound: 80,
      spatialAudio: false,
    ),
  };

  /// Get all available preset names
  List<String> get presetNames => _presets.keys.toList();

  /// Apply a preset by name
  Future<void> applyPreset(String presetName) async {
    if (!_presets.containsKey(presetName)) {
      throw ArgumentError('Preset "$presetName" not found');
    }

    _currentSettings = _presets[presetName]!;
    _settingsController.add(_currentSettings);
  }

  /// Update current settings
  Future<void> updateSettings(HeadphoneSettings newSettings) async {
    _currentSettings = newSettings;
    _settingsController.add(_currentSettings);
  }

  /// Reset settings to default
  Future<void> resetToDefault() async {
    _currentSettings = const HeadphoneSettings();
    _settingsController.add(_currentSettings);
  }

  /// Save current settings as a custom preset
  Future<void> saveAsPreset(String name) async {
    // Implementation would typically save to persistent storage
    // For now, we'll just throw an error
    throw UnimplementedError('Custom preset saving not implemented yet');
  }

  /// Get a preset by name
  HeadphoneSettings? getPreset(String name) => _presets[name];

  /// Dispose of the service
  void dispose() {
    _settingsController.close();
  }
}
