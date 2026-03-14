/// Handles sound effects and feedback audio.
/// Uses a safe wrapper around AudioPlayers.
/// Add actual .mp3 files to assets/sounds/ for working audio.
class AudioService {
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  Future<void> init() async {
    // AudioPlayer init will go here once sound files are added
  }

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  Future<void> playCorrect() async {
    if (!_soundEnabled) return;
    // TODO: Add audioplayers play call once assets/sounds/correct.mp3 exists
  }

  Future<void> playWrong() async {
    if (!_soundEnabled) return;
  }

  Future<void> playSuccess() async {
    if (!_soundEnabled) return;
  }

  Future<void> playTap() async {
    if (!_soundEnabled) return;
  }

  Future<void> playCoin() async {
    if (!_soundEnabled) return;
  }

  Future<void> playCountdown() async {
    if (!_soundEnabled) return;
  }

  void dispose() {}
}
