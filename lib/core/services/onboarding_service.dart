import 'package:shared_preferences/shared_preferences.dart';

/// Service managing Onboarding and Home Tour completion state
class OnboardingService {
  static const String _keyOnboardingComplete = 'cp_onboarding_complete_v1';
  static const String _keyTourComplete = 'cp_home_tour_complete_v1';

  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyOnboardingComplete) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboardingComplete, true);
    } catch (_) {}
  }

  static Future<bool> isTourCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyTourComplete) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> completeTour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTourComplete, true);
    } catch (_) {}
  }

  static Future<void> resetAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOnboardingComplete);
      await prefs.remove(_keyTourComplete);
    } catch (_) {}
  }
}
