import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages in-app review prompts.
/// Uses smart triggers to ask for reviews at optimal moments.
/// When ready, integrate with in_app_review package.
class ReviewService {
  static const String _levelsCompletedKey = 'review_levels_completed';
  static const String _dailyStreakKey = 'review_daily_streaks';
  static const String _hasReviewedKey = 'has_reviewed';
  static const String _lastPromptDateKey = 'last_review_prompt_date';
  static const String _promptCountKey = 'review_prompt_count';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get hasReviewed => _prefs.getBool(_hasReviewedKey) ?? false;
  int get levelsCompleted => _prefs.getInt(_levelsCompletedKey) ?? 0;
  int get dailyStreaks => _prefs.getInt(_dailyStreakKey) ?? 0;
  int get promptCount => _prefs.getInt(_promptCountKey) ?? 0;

  Future<void> recordLevelComplete() async {
    await _prefs.setInt(_levelsCompletedKey, levelsCompleted + 1);
  }

  Future<void> recordDailyStreak(int streak) async {
    if (streak > dailyStreaks) {
      await _prefs.setInt(_dailyStreakKey, streak);
    }
  }

  /// Check if we should show a review prompt
  /// Smart triggers:
  /// - After 10 completed levels (first time)
  /// - After 3 daily streaks
  /// - After 25 levels (if not reviewed yet)
  /// - Max 3 prompts ever
  /// - At least 7 days between prompts
  bool shouldPromptReview() {
    if (hasReviewed) return false;
    if (promptCount >= 3) return false;

    // Check cooldown
    final lastPrompt = _prefs.getString(_lastPromptDateKey);
    if (lastPrompt != null) {
      final lastDate = DateTime.tryParse(lastPrompt);
      if (lastDate != null) {
        final daysSince = DateTime.now().difference(lastDate).inDays;
        if (daysSince < 7) return false;
      }
    }

    // Trigger conditions
    if (levelsCompleted >= 10 && promptCount == 0) return true;
    if (dailyStreaks >= 3 && promptCount <= 1) return true;
    if (levelsCompleted >= 25 && promptCount <= 2) return true;

    return false;
  }

  /// Record that we showed a review prompt
  Future<void> recordPromptShown() async {
    await _prefs.setInt(_promptCountKey, promptCount + 1);
    await _prefs.setString(
      _lastPromptDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Record that user reviewed
  Future<void> recordReviewed() async {
    await _prefs.setBool(_hasReviewedKey, true);
  }

  /// Show the native in-app review dialog (Google Play).
  Future<void> requestReview() async {
    await recordPromptShown();
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        // If the user completes the review, mark recorded.
        // (Google doesn't tell us if they actually rated — treat prompt as success.)
        await recordReviewed();
      }
    } catch (e) {
      debugPrint('ReviewService: requestReview failed: $e');
    }
  }

  /// Opens the Play Store listing for a manual review.
  Future<void> openStoreListing() async {
    try {
      final inAppReview = InAppReview.instance;
      await inAppReview.openStoreListing(
        appStoreId: null,
        microsoftStoreId: null,
      );
    } catch (e) {
      debugPrint('ReviewService: openStoreListing failed: $e');
    }
  }
}
