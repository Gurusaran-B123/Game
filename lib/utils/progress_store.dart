import 'package:shared_preferences/shared_preferences.dart';

import '../models/level_model.dart';

/// Everything saved on the phone: stars for every task, spent stars, album.
class Progress {
  Progress(this.stars, this.spent);

  /// stars[level][task] = 0..3 (best result)
  final List<List<int>> stars;
  final int spent;

  int levelStars(int level) => stars[level].fold<int>(0, (a, b) => a + b);
  int get totalStars =>
      stars.fold<int>(0, (a, l) => a + l.fold<int>(0, (x, y) => x + y));

  /// Stars you can still spend on extra time.
  int get wallet => totalStars - spent < 0 ? 0 : totalStars - spent;

  bool levelUnlocked(int level) => level == 0 || stars[level - 1][kTasksPerLevel - 1] > 0;
  bool taskUnlocked(int level, int task) => task == 0 || stars[level][task - 1] > 0;
}

/// Saves progress with shared_preferences. Every call is safe: on any error
/// it just returns an empty result.
class ProgressStore {
  ProgressStore._();

  static String _k(int level, int task) => 't_${level}_$task';

  static Future<Progress> load() async {
    final stars = List.generate(kLevels.length, (_) => List.filled(kTasksPerLevel, 0));
    var spent = 0;
    try {
      final p = await SharedPreferences.getInstance();
      for (var l = 0; l < kLevels.length; l++) {
        for (var t = 0; t < kTasksPerLevel; t++) {
          stars[l][t] = p.getInt(_k(l, t)) ?? 0;
        }
      }
      spent = p.getInt('spent') ?? 0;
    } catch (_) {}
    return Progress(stars, spent);
  }

  /// Keeps the best star count of a task.
  static Future<void> saveTask(int level, int task, int stars) async {
    try {
      final p = await SharedPreferences.getInstance();
      final old = p.getInt(_k(level, task)) ?? 0;
      if (stars > old) await p.setInt(_k(level, task), stars);
    } catch (_) {}
  }

  /// Spends [n] stars. Returns false if there are not enough.
  static Future<bool> spend(int n) async {
    try {
      final pr = await load();
      if (pr.wallet < n) return false;
      final p = await SharedPreferences.getInstance();
      await p.setInt('spent', pr.spent + n);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Names of babies the player has hatched at least once.
  static Future<Set<String>> album() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (p.getStringList('album') ?? <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> addToAlbum(String name) async {
    try {
      final p = await SharedPreferences.getInstance();
      final list = p.getStringList('album') ?? <String>[];
      if (!list.contains(name)) {
        list.add(name);
        await p.setStringList('album', list);
      }
    } catch (_) {}
  }
}
