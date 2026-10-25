import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:applovin_max/applovin_max.dart';
import '../config/ad_config.dart';

/// AppLovin MAX ad service.
/// Handles banner, interstitial, and rewarded ads.
/// Gracefully no-ops when AppLovin isn't configured yet (see AdConfig).
class AdService {
  bool _isInitialized = false;
  bool _adsRemoved = false;
  int _gameCompleteCount = 0;

  bool _interstitialLoaded = false;
  bool _rewardedLoaded = false;

  Completer<bool>? _rewardedCompleter;

  bool get adsRemoved => _adsRemoved;
  bool get isInitialized => _isInitialized;
  bool get hasRewardedAd => _rewardedLoaded;

  /// Banner ad unit ID (used by widgets showing inline banners).
  static String get bannerAdUnitId => AdConfig.bannerAdUnitId;

  Future<void> init() async {
    if (_isInitialized) return;
    if (!AdConfig.isConfigured) {
      debugPrint('AdService: AppLovin not configured — running in no-ad mode');
      _isInitialized = true;
      return;
    }

    try {
      // ── Family-friendly ad content filters ──
      // The SDK-level hint — networks that honour it will cap to G-rated ads.
      // Primary content blocking happens in AppLovin Dashboard > Ad Review >
      // Block Categories (see README / PLAY_STORE_LISTING.md).
      AppLovinMAX.setExtraParameter('max_ad_content_rating', 'g');
      AppLovinMAX.setExtraParameter('is_age_restricted_user', 'true');

      final config = await AppLovinMAX.initialize(AdConfig.sdkKey);
      if (config == null) {
        debugPrint('AdService: AppLovin init returned null config');
        return;
      }

      _isInitialized = true;
      _attachInterstitialListener();
      _attachRewardedListener();
      _loadInterstitialAd();
      _loadRewardedAd();
      debugPrint('AdService: AppLovin MAX initialized (family-friendly mode)');
    } catch (e) {
      debugPrint('AdService: AppLovin init failed: $e');
    }
  }

  void setAdsRemoved(bool removed) {
    _adsRemoved = removed;
  }

  // ═══════════ Interstitial ═══════════
  void _attachInterstitialListener() {
    AppLovinMAX.setInterstitialListener(InterstitialListener(
      onAdLoadedCallback: (ad) {
        _interstitialLoaded = true;
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        _interstitialLoaded = false;
        // Retry after delay
        Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
      },
      onAdDisplayedCallback: (ad) {},
      onAdDisplayFailedCallback: (ad, error) {
        _interstitialLoaded = false;
        _loadInterstitialAd();
      },
      onAdClickedCallback: (ad) {},
      onAdHiddenCallback: (ad) {
        _interstitialLoaded = false;
        _loadInterstitialAd();
      },
    ));
  }

  void _loadInterstitialAd() {
    if (_adsRemoved || !AdConfig.isConfigured) return;
    AppLovinMAX.loadInterstitial(AdConfig.interstitialAdUnitId);
  }

  /// Call after each game completion. Shows interstitial every N games.
  void onGameComplete() {
    if (_adsRemoved) return;
    _gameCompleteCount++;
    if (_gameCompleteCount >= AdConfig.interstitialFrequency) {
      showInterstitialAd();
      _gameCompleteCount = 0;
    }
  }

  Future<void> showInterstitialAd() async {
    if (_adsRemoved || !_isInitialized || !AdConfig.isConfigured) return;
    final isReady =
        await AppLovinMAX.isInterstitialReady(AdConfig.interstitialAdUnitId) ??
            false;
    if (isReady) {
      AppLovinMAX.showInterstitial(AdConfig.interstitialAdUnitId);
    } else {
      _loadInterstitialAd();
    }
  }

  // ═══════════ Rewarded ═══════════
  void _attachRewardedListener() {
    AppLovinMAX.setRewardedAdListener(RewardedAdListener(
      onAdLoadedCallback: (ad) {
        _rewardedLoaded = true;
      },
      onAdLoadFailedCallback: (adUnitId, error) {
        _rewardedLoaded = false;
        Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
      },
      onAdDisplayedCallback: (ad) {},
      onAdDisplayFailedCallback: (ad, error) {
        _rewardedLoaded = false;
        _completeRewarded(false);
        _loadRewardedAd();
      },
      onAdClickedCallback: (ad) {},
      onAdHiddenCallback: (ad) {
        _rewardedLoaded = false;
        // If the user closed without earning, complete false
        if (_rewardedCompleter != null && !_rewardedCompleter!.isCompleted) {
          _completeRewarded(false);
        }
        _loadRewardedAd();
      },
      onAdReceivedRewardCallback: (ad, reward) {
        _completeRewarded(true);
      },
    ));
  }

  void _loadRewardedAd() {
    if (_adsRemoved || !AdConfig.isConfigured) return;
    AppLovinMAX.loadRewardedAd(AdConfig.rewardedAdUnitId);
  }

  void _completeRewarded(bool value) {
    if (_rewardedCompleter != null && !_rewardedCompleter!.isCompleted) {
      _rewardedCompleter!.complete(value);
    }
  }

  /// Shows a rewarded ad. Returns true if the reward was earned.
  Future<bool> showRewardedAd() async {
    // If ads are removed or not configured, grant reward anyway so users
    // still benefit when ads are unavailable.
    if (_adsRemoved || !AdConfig.isConfigured) return true;
    if (!_isInitialized) return false;

    final isReady =
        await AppLovinMAX.isRewardedAdReady(AdConfig.rewardedAdUnitId) ?? false;
    if (!isReady) {
      _loadRewardedAd();
      return false;
    }

    _rewardedCompleter = Completer<bool>();
    AppLovinMAX.showRewardedAd(AdConfig.rewardedAdUnitId);
    final result =
        await _rewardedCompleter!.future.timeout(const Duration(minutes: 3),
      onTimeout: () => false,
    );
    return result;
  }

  void preloadAds() {
    if (_adsRemoved || !_isInitialized || !AdConfig.isConfigured) return;
    if (!_interstitialLoaded) _loadInterstitialAd();
    if (!_rewardedLoaded) _loadRewardedAd();
  }

  void dispose() {
    // AppLovin MAX manages ad instances internally; nothing to dispose here.
  }
}
