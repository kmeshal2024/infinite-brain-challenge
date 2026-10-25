/// ═══════════════════════════════════════════════════════════════════════════
/// AppLovin MAX Configuration
/// ═══════════════════════════════════════════════════════════════════════════
///
/// STEPS TO COMPLETE SETUP:
///
/// 1. Sign up at https://dash.applovin.com/signup
/// 2. Add your app → get your SDK Key
/// 3. Create 3 ad units:
///       - Banner
///       - Interstitial
///       - Rewarded
/// 4. Replace the placeholder values below with your real IDs
/// 5. Enable test mode during development (setTestDeviceAdvertisingIds)
///
/// Until real IDs are set, ads will fail gracefully and the app still works.
/// ═══════════════════════════════════════════════════════════════════════════
class AdConfig {
  AdConfig._();

  /// Replace with your AppLovin SDK Key from dash.applovin.com → Account → Keys
  static const String sdkKey = 'YOUR_APPLOVIN_SDK_KEY_HERE';

  /// Replace with your Banner Ad Unit ID
  static const String bannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';

  /// Replace with your Interstitial Ad Unit ID
  static const String interstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';

  /// Replace with your Rewarded Ad Unit ID
  static const String rewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';

  /// When true, real ads are disabled — useful for development
  /// and if AppLovin isn't configured yet. Flip to false when you add real IDs.
  static const bool disableAds = true;

  /// Show an interstitial every N game completions.
  static const int interstitialFrequency = 3;

  /// Family-friendly content filter is applied at init() time via
  /// AppLovin SDK extra parameters (max_ad_content_rating=g,
  /// is_age_restricted_user=true).
  ///
  /// The SDK hint is not enough on its own — AppLovin relies on the
  /// **dashboard blocking** for hard content filtering. See APPLOVIN_SETUP.md
  /// for the full list of categories to block.

  static bool get isConfigured =>
      !disableAds &&
      sdkKey != 'YOUR_APPLOVIN_SDK_KEY_HERE' &&
      bannerAdUnitId != 'YOUR_BANNER_AD_UNIT_ID' &&
      interstitialAdUnitId != 'YOUR_INTERSTITIAL_AD_UNIT_ID' &&
      rewardedAdUnitId != 'YOUR_REWARDED_AD_UNIT_ID';
}
