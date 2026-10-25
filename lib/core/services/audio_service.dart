import 'package:audioplayers/audioplayers.dart';

/// Handles all game sound effects using AudioPlayers.
/// Pre-loads sounds for instant playback during gameplay.
class AudioService {
  bool _soundEnabled = true;
  bool _initialized = false;

  // Dedicated players for overlapping sounds
  final AudioPlayer _sfxPlayer1 = AudioPlayer();
  final AudioPlayer _sfxPlayer2 = AudioPlayer();
  final AudioPlayer _sfxPlayer3 = AudioPlayer();
  int _currentPlayer = 0;

  bool get soundEnabled => _soundEnabled;

  Future<void> init() async {
    if (_initialized) return;
    // Set low latency mode for all players
    await _sfxPlayer1.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer2.setReleaseMode(ReleaseMode.stop);
    await _sfxPlayer3.setReleaseMode(ReleaseMode.stop);
    _initialized = true;
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  AudioPlayer get _nextPlayer {
    _currentPlayer = (_currentPlayer + 1) % 3;
    switch (_currentPlayer) {
      case 0:
        return _sfxPlayer1;
      case 1:
        return _sfxPlayer2;
      default:
        return _sfxPlayer3;
    }
  }

  Future<void> _play(String assetPath, {double volume = 1.0}) async {
    if (!_soundEnabled) return;
    try {
      final player = _nextPlayer;
      await player.stop();
      await player.setVolume(volume);
      await player.play(AssetSource(assetPath));
    } catch (_) {
      // Silently fail - sound should never crash the game
    }
  }

  Future<void> playCorrect() => _play('sounds/correct.wav', volume: 0.7);

  Future<void> playWrong() => _play('sounds/wrong.wav', volume: 0.6);

  Future<void> playSuccess() => _play('sounds/success.wav', volume: 0.8);

  Future<void> playFail() => _play('sounds/fail.wav', volume: 0.6);

  Future<void> playTap() => _play('sounds/tap.wav', volume: 0.5);

  Future<void> playCoin() => _play('sounds/coin.wav', volume: 0.7);

  Future<void> playCountdown() => _play('sounds/countdown.wav', volume: 0.5);

  Future<void> playStar() => _play('sounds/star.wav', volume: 0.7);

  Future<void> playButton() => _play('sounds/button.wav', volume: 0.5);

  Future<void> playGameStart() => _play('sounds/game_start.wav', volume: 0.6);

  void dispose() {
    _sfxPlayer1.dispose();
    _sfxPlayer2.dispose();
    _sfxPlayer3.dispose();
  }
}
