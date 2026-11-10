import 'package:shared_preferences/shared_preferences.dart';

/// Saves which levels are unlocked and the best stars per level.
class ProgressStore {
  ProgressStore._();

  /// Highest level number the player may open (starts at 1).
  static Future<int> unlocked() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt('unlocked') ?? 1;
    } catch (_) {
      return 1;
    }
  }

  static Future<int> stars(int level) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt('stars_$level') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> saveResult(int level, int stars, int totalLevels) async {
    try {
      final p = await SharedPreferences.getInstance();
      final old = p.getInt('stars_$level') ?? 0;
      if (stars > old) await p.setInt('stars_$level', stars);
      final next = level + 1;
      final cur = p.getInt('unlocked') ?? 1;
      if (next <= totalLevels && next > cur) await p.setInt('unlocked', next);
    } catch (_) {}
  }
}
