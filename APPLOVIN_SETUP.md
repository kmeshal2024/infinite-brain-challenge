# AppLovin MAX Setup Guide

This app is coded for AppLovin MAX ads. Follow these steps once to start earning.

---

## Part 1: Create AppLovin account (one-time, ~10 min)

1. Go to https://dash.applovin.com/signup
2. Sign up with your email (same email you want paid on)
3. Verify email → fill in payment/tax details
4. Wait for approval (usually **1–2 days**)

## Part 2: Add your app

1. In the dashboard: **Applications → Add App**
2. Select "Android" → enter your Google Play URL
   ```
   https://play.google.com/store/apps/details?id=com.infinitebrain.infinite_brain_challenge
   ```
3. AppLovin auto-fills name, icon, etc.

## Part 3: Create 3 ad units

Go to **MAX → Ad Units** → click "Create New Ad Unit" three times:

| Type | Name | Placement |
|------|------|-----------|
| Banner | Infinite Brain — Banner | Bottom of screen |
| Interstitial | Infinite Brain — Interstitial | Every 3 games |
| Rewarded | Infinite Brain — Rewarded | "Watch for coins" button |

After each, copy the **Ad Unit ID** (looks like `1234567890abcdef`).

## Part 4: Get your SDK Key

**Account → Keys → SDK Key** → copy the long string.

## Part 5: Paste into the app

Open `lib/core/config/ad_config.dart` and replace the 4 placeholder strings:

```dart
static const String sdkKey = 'PASTE_YOUR_SDK_KEY_HERE';
static const String bannerAdUnitId = 'PASTE_YOUR_BANNER_AD_UNIT_ID';
static const String interstitialAdUnitId = 'PASTE_YOUR_INTERSTITIAL_AD_UNIT_ID';
static const String rewardedAdUnitId = 'PASTE_YOUR_REWARDED_AD_UNIT_ID';
static const bool disableAds = false;   // ← flip to false
```

Then rebuild:
```bash
flutter build appbundle --release
```
Upload the new AAB to Google Play.

---

## Part 6 (IMPORTANT): Family-friendly ad filtering

**This is the critical step to block adult content, movie trailers, etc.**

### A. Set the app's content rating
1. Open your app in AppLovin dashboard
2. **Settings → App Info → Max Ad Content Rating**
3. Set to **"All Audiences"** (equivalent to G — no mature content)
4. Save

### B. Block categories (the big one)
1. Go to **Ad Review → Category Blocking**
2. Block **all** of the following categories:
   - ☑ Alcohol
   - ☑ Tobacco & Smoking
   - ☑ Drugs
   - ☑ Firearms & Weapons
   - ☑ Gambling
   - ☑ Dating
   - ☑ Adult (usually blocked by default under G rating, but double-check)
   - ☑ Violence / Horror
   - ☑ Religion (optional, if you want neutral)
   - ☑ Political (optional)
   - ☑ Movies / TV with Mature themes — **this is the one that blocks movie trailers**
3. For remaining movie categories that AREN'T horror/mature, you can allow or block based on preference
4. Save

### C. Block specific advertisers (optional but recommended)
1. **Ad Review → Creative Review**
2. Enable email notifications for new creatives
3. Reject any ads you don't want (they stop serving within 24 hours)

### D. Pre-block commonly problematic advertisers
1. **Ad Review → Advertiser Blocking**
2. Add blocks for:
   - Any competing brain-training apps you want to exclude (optional)
   - Known crypto/forex/gambling brands (if not already blocked by categories)

### E. Turn on "Kid-Safe" mode (toughest setting)
1. **Applications → (your app) → Settings**
2. Look for **"Audience: Made for Kids"** or **"COPPA compliance"**
3. Enable it — this forces all ads to be kid-safe regardless of network

---

## What gets blocked with this setup

| Ad type | Status |
|---------|--------|
| Adult / dating ads | ❌ Blocked |
| Alcohol & tobacco | ❌ Blocked |
| Gambling / casino | ❌ Blocked |
| Movie trailers (R-rated) | ❌ Blocked |
| Movie trailers (PG-13) | ❌ Blocked (under G rating) |
| Horror game ads | ❌ Blocked |
| Violent game ads | ❌ Blocked |
| Other mobile games | ✅ Allowed (these pay well) |
| E-commerce, brands, services | ✅ Allowed |
| Educational apps | ✅ Allowed |

---

## Part 7: Payout setup

1. **Account → Payments**
2. Choose payment method:
   - **Wire transfer** (best for international, $2000 min)
   - **PayPal** ($20 min)
   - **Payoneer** ($20 min)
3. Enter tax form (W-8BEN if outside US, W-9 if US)
4. Set payout threshold
5. Payments go out monthly on **Net-30** terms

**Typical first-month revenue for a brain game with ~1000 DAU:** $50–$200  
**Typical after ad optimization (3-6 months):** $500–$2000+

---

## Testing ads before going live

Once your SDK key is in `ad_config.dart`, run in debug mode. To see test ads on your device:

1. Find your device's Advertising ID:
   - Android: Settings → Google → Ads → Your advertising ID
2. Add to `ad_service.dart` **above** the `initialize()` call:
   ```dart
   AppLovinMAX.setTestDeviceAdvertisingIds(['YOUR_ADVERTISING_ID']);
   ```
3. Run the app — you'll see TEST ads (not real ones, so no accidental self-clicks)
4. **Remove that line before production build**

---

## Why AppLovin won't close your account (unlike AdMob)

| Reason | AdMob | AppLovin |
|--------|-------|----------|
| Clicking your own ads (accident) | Account closed | Temporary reduced fill |
| Low traffic / slow start | No issue | No issue |
| Ad network policy changes | Very strict | Flexible |
| Appeal process | Mostly fails | Usually successful |

---

## When everything is set up

Your revenue dashboard: https://dash.applovin.com/revenue

Refresh metrics every **24h** (not real-time, so don't panic).
