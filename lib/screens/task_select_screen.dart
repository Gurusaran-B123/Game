import 'package:flutter/material.dart';

import '../models/level_model.dart';
import '../utils/progress_store.dart';
import '../widgets/ui_bits.dart';
import 'game_screen.dart';

/// The 10 tasks of one level. Every task has up to 3 stars.
class TaskSelectScreen extends StatefulWidget {
  const TaskSelectScreen({super.key, required this.levelIndex});
  final int levelIndex;

  @override
  State<TaskSelectScreen> createState() => _TaskSelectScreenState();
}

class _TaskSelectScreenState extends State<TaskSelectScreen> {
  Progress? _pr;
  late final LevelModel level = kLevels[widget.levelIndex];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ProgressStore.load();
    if (mounted) setState(() => _pr = p);
  }

  Future<void> _open(int t) async {
    final pr = _pr;
    if (pr == null) return;
    if (!pr.taskUnlocked(widget.levelIndex, t)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Finish Task $t first!', style: fancyText(18)),
          duration: const Duration(seconds: 1),
        ));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameScreen(levelIndex: widget.levelIndex, taskIndex: t)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final pr = _pr;
    final stars = pr?.levelStars(widget.levelIndex) ?? 0;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            level.background,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: level.cardColor),
          ),
          Container(color: const Color(0x55000000)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        color: const Color(0xFFEF5350),
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(level.title, style: fancyText(30)),
                        ),
                      ),
                      HudChip(
                        icon: Icons.star_rounded,
                        text: '$stars/${kTasksPerLevel * 3}',
                        color: const Color(0xFFFFD54F),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Text(
                    'Stars to spend: ${pr?.wallet ?? 0}   (3 stars = +15 sec in a task)',
                    style: fancyText(14, color: Colors.white70),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.55,
                    ),
                    itemCount: kTasksPerLevel,
                    itemBuilder: (context, t) {
                      final task = level.tasks[t];
                      final locked = pr != null && !pr.taskUnlocked(widget.levelIndex, t);
                      final s = pr?.stars[widget.levelIndex][t] ?? 0;
                      return _TaskTile(
                        number: t + 1,
                        title: task.title,
                        stars: s,
                        locked: locked,
                        color: level.cardColor,
                        boss: t == kTasksPerLevel - 1,
                        onTap: () => _open(t),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.number,
    required this.title,
    required this.stars,
    required this.locked,
    required this.color,
    required this.boss,
    required this.onTap,
  });

  final int number;
  final String title;
  final int stars;
  final bool locked;
  final Color color;
  final bool boss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = locked ? const Color(0xFF8A8A8A) : (boss ? const Color(0xFFE53935) : color);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: darker(c, 0.4), offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: locked
                  ? const Icon(Icons.lock_rounded, color: Color(0xFF8A8A8A), size: 22)
                  : Text('$number', style: fancyText(22, color: darker(c, 0.2))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: fancyText(17)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          Icons.star_rounded,
                          size: 22,
                          color: i < stars ? const Color(0xFFFFC107) : Colors.white54,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
