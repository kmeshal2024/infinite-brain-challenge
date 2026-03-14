# Infinite Brain Challenge - Launch Execution Guide

## BUILD STATUS
- **AAB:** `build/app/outputs/bundle/release/app-release.aab` (43.1MB)
- **Signed:** CN=Khalid Binmeshal, SHA256withRSA
- **Version:** 1.0.0+1
- **Package:** com.infinitebrain.infinite_brain_challenge
- **Target SDK:** 35 | **Min SDK:** 21

---

## STEP 1: HOST WEB PRESENCE (15 minutes)

### Option A: GitHub Pages (FASTEST - RECOMMENDED)

1. Create a GitHub repo: `infinite-brain-games` (umbrella for all future games)
2. Push the `docs/` folder to the repo
3. Go to repo Settings > Pages > Source: Deploy from branch > Branch: main > Folder: /docs
4. Your URLs will be:
   - Landing: `https://YOUR-USERNAME.github.io/infinite-brain-games/`
   - Privacy: `https://YOUR-USERNAME.github.io/infinite-brain-games/privacy-policy.html`
   - Support: `https://YOUR-USERNAME.github.io/infinite-brain-games/support.html`

### Files Ready:
- `docs/index.html` - Landing page
- `docs/privacy-policy.html` - Privacy policy
- `docs/support.html` - Support & FAQ

### URL for Play Console:
Use the privacy policy URL when creating the app listing.

---

## STEP 2: PLAY CONSOLE - CREATE APP

1. Go to https://play.google.com/console
2. Click "Create app"
3. Fill in:
   - **App name:** Infinite Brain Challenge
   - **Default language:** English (United States)
   - **App or game:** Game
   - **Free or paid:** Free
   - Check all declarations boxes
4. Click "Create app"

---

## STEP 3: STORE LISTING (do this FIRST - it takes longest)

### Main Store Listing

**App name:** `Infinite Brain Challenge`

**Short description:**
```
Train your brain with 4 addictive mini-games. Daily challenges, coins & rewards!
```

**Full description:**
```
Sharpen your mind with Infinite Brain Challenge — a premium brain-training app featuring four addictive mini-games designed to test and improve your cognitive abilities.

FOUR BRAIN-TRAINING GAMES

Pattern Memory
Memorize and reproduce increasingly complex patterns. Each level pushes your visual memory further. How many patterns can you master?

Number Sequence
Crack the code! Analyze number sequences and find the missing values. Exercises logical thinking and mathematical reasoning.

Odd One Out
Spot the difference! Quickly identify the item that doesn't belong. Sharpens your attention to detail and visual processing speed.

Reaction Speed
Test your reflexes! Tap as fast as you can when the signal appears. Track your reaction time and watch yourself improve over days and weeks.

DAILY CHALLENGES
Take on a fresh challenge every day. Complete daily challenges to earn bonus coins and keep your training streak alive. Consistency is key to brain fitness!

EARN & SPEND
Collect coins and stars as you play. Use them in the shop to unlock hints, power-ups, and more. Every game rewards your effort.

YOUR PROGRESS, YOUR PROFILE
Track your improvement with detailed stats. See how your scores evolve across all four games. Set personal records and push your limits.

DESIGNED FOR FOCUS
A clean, dark-themed interface keeps distractions away so you can focus on what matters — training your brain. No clutter, just pure gameplay.

KEY FEATURES
- 4 unique brain-training mini-games
- Progressive difficulty that adapts to your skill
- Daily challenges with bonus rewards
- Coins, stars, and hints economy
- Personal profile with performance tracking
- Beautiful dark theme designed for extended play
- Works offline — no internet required to play
- No ads in v1.0 — pure, uninterrupted gameplay

Whether you have 2 minutes or 20, Infinite Brain Challenge is the perfect way to give your brain a workout. Download now and start training!
```

### Graphics Required
- **Feature Graphic (1024x500):** Generated at `assets/store/feature_graphic.png`
  - Add text overlay: "INFINITE BRAIN CHALLENGE" + "4 Brain-Training Games"
- **App Icon (512x512):** Already generated at `assets/icon/app_icon.png`
- **Phone Screenshots:** Take 4-6 screenshots (see screenshot plan below)

### Screenshot Plan (minimum 2, recommended 6)
Take these on a Pixel-sized emulator or real device:

1. **Home Screen** - Shows daily rewards, streak, game cards
2. **Pattern Memory gameplay** - Mid-game showing the grid
3. **Number Sequence gameplay** - Showing the sequence puzzle
4. **Result Screen** - Showing 3 stars, score, coins earned
5. **Achievements Screen** - Showing unlocked achievements
6. **Daily Rewards Screen** - Showing the 7-day calendar

**How to capture:** Run `flutter run` on device/emulator, navigate to each screen, take screenshot.

---

## STEP 4: APP ACCESS

- Select: **All functionality is available without special access**
- No login required, no special access needed

---

## STEP 5: ADS DECLARATION

- Select: **No, my app does not contain ads**
- (Ads are not integrated in v1.0)

---

## STEP 6: CONTENT RATING

Fill out the IARC questionnaire:
- **Violence:** No
- **Sexual content:** No
- **Language:** No
- **Controlled substance:** No
- **Gambling:** No (virtual coins are NOT purchasable with real money)
- **User interaction:** No (no multiplayer, no chat, no user-generated content)

**Expected rating:** Everyone (PEGI 3, ESRB Everyone)

---

## STEP 7: TARGET AUDIENCE

- **Target age group:** All ages
- **Designed for children?** Select "No" (simpler compliance path)
  - The app IS child-safe, but selecting "Yes" triggers additional compliance requirements
  - This does NOT prevent children from using it

---

## STEP 8: DATA SAFETY

### Overview
This app collects NO data. Answer as follows:

**Does your app collect or share any of the required user data types?**
→ **No**

**Does your app collect any other data?**
→ **No**

**Is all of the user data collected by your app encrypted in transit?**
→ Not applicable (no data transmitted)

**Do you provide a way for users to request that their data is deleted?**
→ Not applicable (no data collected)

**Committed to play Families Policy?**
→ No (skip this for faster review)

---

## STEP 9: PRICING & DISTRIBUTION

- **Price:** Free
- **Countries:** All available countries
- **Contains ads:** No

---

## STEP 10: UPLOAD RELEASE

1. Go to **Production** (left menu)
2. Click **Create new release**
3. Upload: `build/app/outputs/bundle/release/app-release.aab`
4. **Release name:** 1.0.0 (auto-filled)
5. **Release notes:**
```
Welcome to Infinite Brain Challenge!

What's included in this first release:
- 4 brain-training mini-games: Pattern Memory, Number Sequence, Odd One Out, and Reaction Speed
- Daily challenge mode with bonus rewards
- Coins, stars, and hints reward system
- Player profile with stats tracking
- Clean, dark-themed design
- Full offline support

Start training your brain today!
```
6. Click **Save**
7. Click **Review release**
8. Click **Start rollout to production**

---

## STEP 11: SUBMIT FOR REVIEW

After all sections show green checkmarks:
1. Go to **Publishing overview**
2. Click **Send changes for review**
3. Review typically takes **a few hours to 3 days** for new apps

---

## SCREENSHOTS CAPTURE COMMANDS

```bash
# Start app on connected device
flutter run --release

# Take screenshot via adb (if using physical device)
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png screenshot_home.png
```

Or use Android Studio's built-in screenshot tool.

---

## POST-LAUNCH CHECKLIST

After app is approved:
- [ ] Verify the Play Store listing looks correct
- [ ] Test the Play Store download on a real device
- [ ] Update the landing page with actual Play Store URL
- [ ] Share on social media
- [ ] Monitor Play Console for crashes/ANRs
- [ ] Plan v1.1 (Firebase Analytics, Sound effects, In-app review)
