/// Ad service - placeholder for Google AdMob integration.
/// Provides clean hooks for rewarded, interstitial, and banner ads.
class AdService {
  bool _isInitialized = false;
  bool _adsRemoved = false;

  bool get adsRemoved => _adsRemoved;

  Future<void> init() async {
    // MobileAds.instance.initialize();
    _isInitialized = true;
  }

  void setAdsRemoved(bool removed) {
    _adsRemoved = removed;
  }

  /// Shows a rewarded ad. Returns true if reward should be granted.
  Future<bool> showRewardedAd() async {
    if (_adsRemoved || !_isInitialized) return true; // Grant reward if no ads
    // Placeholder - integrate with google_mobile_ads
    // For MVP, simulate ad completion
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Shows an interstitial ad at natural break points.
  Future<void> showInterstitialAd() async {
    if (_adsRemoved || !_isInitialized) return;
    // Placeholder - integrate with google_mobile_ads
  }

  /// Preloads ads for faster display.
  void preloadAds() {
    if (_adsRemoved || !_isInitialized) return;
    // Preload rewarded and interstitial
  }

  void dispose() {
    // Dispose ad resources
  }
}
