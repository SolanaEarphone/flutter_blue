// Copyright 2024, SolanaEarphone.
// All rights reserved.

/// Represents the audio settings for a headphone device
class HeadphoneSettings {
  /// Volume level (0-100)
  final int volume;

  /// Bass boost level (0-100)
  final int bassBoost;

  /// Treble level (0-100)
  final int treble;

  /// Noise cancellation mode
  final NoiseCancellationMode noiseCancellation;

  /// Ambient sound mode level (0-100)
  final int ambientSound;

  /// Whether spatial audio is enabled
  final bool spatialAudio;

  /// Whether voice assistant is enabled
  final bool voiceAssistant;

  /// Whether touch controls are enabled
  final bool touchControls;

  const HeadphoneSettings({
    this.volume = 50,
    this.bassBoost = 0,
    this.treble = 50,
    this.noiseCancellation = NoiseCancellationMode.off,
    this.ambientSound = 0,
    this.spatialAudio = false,
    this.voiceAssistant = true,
    this.touchControls = true,
  });

  HeadphoneSettings copyWith({
    int? volume,
    int? bassBoost,
    int? treble,
    NoiseCancellationMode? noiseCancellation,
    int? ambientSound,
    bool? spatialAudio,
    bool? voiceAssistant,
    bool? touchControls,
  }) {
    return HeadphoneSettings(
      volume: volume ?? this.volume,
      bassBoost: bassBoost ?? this.bassBoost,
      treble: treble ?? this.treble,
      noiseCancellation: noiseCancellation ?? this.noiseCancellation,
      ambientSound: ambientSound ?? this.ambientSound,
      spatialAudio: spatialAudio ?? this.spatialAudio,
      voiceAssistant: voiceAssistant ?? this.voiceAssistant,
      touchControls: touchControls ?? this.touchControls,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeadphoneSettings &&
          runtimeType == other.runtimeType &&
          volume == other.volume &&
          bassBoost == other.bassBoost &&
          treble == other.treble &&
          noiseCancellation == other.noiseCancellation &&
          ambientSound == other.ambientSound &&
          spatialAudio == other.spatialAudio &&
          voiceAssistant == other.voiceAssistant &&
          touchControls == other.touchControls;

  @override
  int get hashCode =>
      volume.hashCode ^
      bassBoost.hashCode ^
      treble.hashCode ^
      noiseCancellation.hashCode ^
      ambientSound.hashCode ^
      spatialAudio.hashCode ^
      voiceAssistant.hashCode ^
      touchControls.hashCode;
}

/// Represents different noise cancellation modes
enum NoiseCancellationMode {
  off,
  on,
  adaptive,
  transparency,
}
