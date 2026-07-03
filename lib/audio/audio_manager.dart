// lib/audio/audio_manager.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer2 = AudioPlayer();
  bool soundEnabled = !kIsWeb; // Disable audio on web by default (files missing)

  Future<void> playFlap() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/flap.mp3'), volume: 0.8);
    } catch (_) {
      // Silently ignore audio errors
    }
  }

  Future<void> playScore() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer2.play(AssetSource('audio/score.mp3'), volume: 1.0);
    } catch (_) {
      // Silently ignore audio errors
    }
  }

  Future<void> playDie() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer.play(AssetSource('audio/die.mp3'), volume: 1.0);
    } catch (_) {
      // Silently ignore audio errors
    }
  }

  Future<void> playLevelUp() async {
    if (!soundEnabled) return;
    try {
      await _sfxPlayer2.play(AssetSource('audio/levelup.mp3'), volume: 1.0);
    } catch (_) {
      // Silently ignore audio errors
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _sfxPlayer2.dispose();
  }
}
