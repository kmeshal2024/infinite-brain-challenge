# Release Checklist — Infinite Brain Challenge v1.0.0

## Pre-Release Verification

- [x] App runs correctly on Chrome (web)
- [x] All 4 mini-games playable: Pattern Memory, Number Sequence, Odd One Out, Reaction Speed
- [x] Coins/stars/hints economy working
- [x] Daily challenge functional
- [x] Profile screen showing stats
- [x] Shop screen working
- [x] Settings screen working
- [x] NDK issue fixed (fresh install of NDK 27.0.12077973)
- [x] Windows Developer Mode enabled for symlink support
- [x] `cupertino_icons` dependency added
- [ ] Test on physical Android device
- [ ] Test on physical iOS device (requires Mac)

## Build Artifacts

- [x] Release AAB built: `build/app/outputs/bundle/release/app-release.aab`
- [x] AAB signed with upload keystore (`upload` alias, CN=Khalid Binmeshal)
- [x] Signing verified with `jarsigner -verify`
- [x] App icons generated (Android adaptive + legacy, iOS, Web)
- [x] Native splash screen configured (dark theme #0D0F1A)

## Files Ready

- [x] `privacy_policy.html` — standalone HTML, ready to host
- [x] `store_listing.md` — title, descriptions, release notes, keywords
- [x] `assets/icon/app_icon.png` — 1024x1024 source icon

---

## Google Play Console Submission

### 1. Create Developer Account
- [ ] Sign up at https://play.google.com/console
- [ ] Pay one-time $25 registration fee
- [ ] Complete identity verification

### 2. Create App
- [ ] Click "Create app" in Play Console
- [ ] App name: **Infinite Brain Challenge**
- [ ] Default language: English (United States)
- [ ] App type: Game
- [ ] Free or Paid: Free
- [ ] Accept declarations

### 3. Store Listing
- [ ] Title: `Infinite Brain Challenge` (24 chars)
- [ ] Short description: from `store_listing.md` (80 chars)
- [ ] Full description: from `store_listing.md`
- [ ] App icon: Upload `assets/icon/app_icon.png` (512x512 will be auto-scaled)
- [ ] Feature graphic: Create 1024x500 banner image
- [ ] Phone screenshots: At least 2 screenshots (min 320px, max 3840px, 16:9 or 9:16)
- [ ] Tablet screenshots: At least 1 (7-inch) and 1 (10-inch) recommended
- [ ] Category: Games > Puzzle
- [ ] Contact email: support@infinitebrain.com
- [ ] Privacy policy URL: Link to hosted `privacy_policy.html`

### 4. Content Rating
- [ ] Complete IARC content rating questionnaire
- [ ] Expected rating: Everyone / PEGI 3
- [ ] No violence, no user-generated content, no personal data collection

### 5. App Content
- [ ] Target audience: All ages (no children-specific content)
- [ ] Ads declaration: No ads in v1.0
- [ ] Data safety section:
  - No data collected
  - No data shared
  - Data stored locally only (SharedPreferences)
  - No account required

### 6. Release Management
- [ ] Go to "Production" > "Create new release"
- [ ] Let Google manage signing (App Signing by Google Play)
- [ ] Upload `app-release.aab`
- [ ] Release name: `1.0.0`
- [ ] Release notes: from `store_listing.md`
- [ ] Review and roll out to production (or start with closed/open testing)

### 7. Post-Submission
- [ ] Wait for review (typically 1-7 days for first submission)
- [ ] Monitor for rejection emails
- [ ] Test the live listing URL once approved

---

## Apple App Store Submission

### 1. Apple Developer Account
- [ ] Enroll at https://developer.apple.com
- [ ] Pay annual $99 fee
- [ ] Complete identity verification

### 2. App Store Connect Setup
- [ ] Go to https://appstoreconnect.apple.com
- [ ] Click "+" > "New App"
- [ ] Platform: iOS
- [ ] Name: **Infinite Brain Challenge**
- [ ] Primary language: English (U.S.)
- [ ] Bundle ID: `com.infinitebrain.infiniteBrainChallenge`
- [ ] SKU: `infinite_brain_challenge_v1`

### 3. Build on macOS
- [ ] Open project on Mac with Xcode installed
- [ ] Run `flutter pub get`
- [ ] Open `ios/Runner.xcworkspace` in Xcode
- [ ] Set Team in Signing & Capabilities
- [ ] Set Bundle Identifier to `com.infinitebrain.infiniteBrainChallenge`
- [ ] Verify minimum deployment target (iOS 12.0+)
- [ ] Run `flutter build ios --release`
- [ ] Archive in Xcode: Product > Archive
- [ ] Upload to App Store Connect via Xcode Organizer

### 4. App Store Listing
- [ ] App name: **Infinite Brain Challenge**
- [ ] Subtitle: e.g., "Train Your Brain Daily"
- [ ] Description: from `store_listing.md`
- [ ] Keywords: `brain,training,puzzle,memory,game,reaction,sequence,challenge,daily,cognitive`
- [ ] Category: Games > Puzzle
- [ ] Content rating: 4+
- [ ] Screenshots: 6.7" (iPhone 15 Pro Max), 6.5" (iPhone 11 Pro Max), 5.5" (iPhone 8 Plus)
- [ ] iPad screenshots if supporting iPad
- [ ] App icon: 1024x1024 (auto-generated, already in Assets.xcassets)
- [ ] Privacy policy URL: Link to hosted `privacy_policy.html`
- [ ] Support URL: your website or support email page

### 5. App Privacy (Data Collection)
- [ ] In App Store Connect > App Privacy:
  - Data types collected: **None**
  - No tracking
  - No third-party analytics (yet)

### 6. Submit for Review
- [ ] Select build from uploaded archives
- [ ] Set version: 1.0.0
- [ ] Release notes: from `store_listing.md`
- [ ] Review information: provide demo credentials if needed (not needed for this app)
- [ ] Submit for review
- [ ] Wait for review (typically 1-3 days)

### 7. Post-Submission
- [ ] Monitor for rejection feedback in Resolution Center
- [ ] Once approved, manually release or auto-release

---

## Assets Still Needed

- [ ] **Feature Graphic** (1024x500 PNG/JPG) for Google Play
- [ ] **Phone Screenshots** (at least 2-8 per device type)
- [ ] **Tablet Screenshots** (recommended for Google Play)
- [ ] **iPad Screenshots** (if supporting iPad on App Store)
- [ ] **Host privacy policy** at a public URL (e.g., GitHub Pages, your website)

## Future Updates (v1.1 Roadmap)

- [ ] Integrate Firebase Analytics
- [ ] Add Google AdMob
- [ ] Add sound effects (audioplayers)
- [ ] Add polish animations (flutter_animate)
- [ ] Add stats charts (fl_chart)
- [ ] Consider Hive for local data storage

---

## Key Project Information

| Item | Value |
|------|-------|
| Package Name (Android) | `com.infinitebrain.infinite_brain_challenge` |
| Bundle ID (iOS) | `com.infinitebrain.infiniteBrainChallenge` |
| Version | 1.0.0+1 |
| Min Android SDK | 21 (Android 5.0) |
| Target Android SDK | 35 |
| Keystore | `C:\Users\dell\upload-keystore.jks` |
| Key Alias | `upload` |
| Flutter | 3.32.2 (stable) |
| Dart | 3.8.1 |
| Gradle | 8.12 |
| AGP | 8.7.3 |
| NDK | 27.0.12077973 |

## Important Security Notes

- **Never commit `key.properties`** to version control (contains keystore passwords)
- **Never commit `upload-keystore.jks`** to version control
- Keep backup copies of the keystore file — losing it means you cannot update the app
- Store keystore password securely (not in plaintext files in the repo)
