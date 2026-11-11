import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/level_model.dart';
import 'screens/album_screen.dart';
import 'screens/task_select_screen.dart';
import 'utils/progress_store.dart';
import 'utils/sound_manager.dart';
import 'widgets/game_overlays.dart';
import 'widgets/ui_bits.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SoundManager.instance.init();
  runApp(const DeploHatchApp());
}

class DeploHatchApp extends StatelessWidget {
  const DeploHatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deplo Hatch - Egg Sort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: kFont,
        colorSchemeSeed: const Color(0xFFFFB300),
      ),
      home: const LevelSelectScreen(),
    );
  }
}

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Progress? _pr;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundManager.instance.playMusic('bgm_farm');
    });
  }

  Future<void> _load() async {
    final p = await ProgressStore.load();
    if (mounted) setState(() => _pr = p);
  }

  Future<void> _open(int index) async {
    final pr = _pr;
    if (pr != null && !pr.levelUnlocked(index)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Finish Task 10 of Level $index first!', style: fancyText(18)),
          duration: const Duration(seconds: 2),
        ));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskSelectScreen(levelIndex: index)),
    );
    if (!mounted) return;
    await _load();
    SoundManager.instance.playMusic('bgm_farm');
  }

  @override
  Widget build(BuildContext context) {
    final pr = _pr;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF81D4FA), Color(0xFFFFF59D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HudChip(
                      icon: Icons.star_rounded,
                      text: '${pr?.wallet ?? 0}',
                      color: const Color(0xFFFFD54F),
                    ),
                    const SizedBox(width: 10),
                    RoundIconButton(
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF43A047),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AlbumScreen()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    RoundIconButton(
                      icon: Icons.settings_rounded,
                      color: const Color(0xFF8E24AA),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => const SettingsDialog(),
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/egg_golden.png',
                height: 74,
                errorBuilder: (c, e, s) => const Icon(Icons.egg_rounded, size: 74, color: Colors.white),
              ),
              Text('Deplo Hatch', style: fancyText(44, color: const Color(0xFFEF6C00))),
              Text('Egg Sort', style: fancyText(26, color: const Color(0xFF5D4037))),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                  itemCount: kLevels.length,
                  itemBuilder: (context, i) => _LevelCard(
                    level: kLevels[i],
                    stars: pr?.levelStars(i) ?? 0,
                    locked: pr != null && !pr.levelUnlocked(i),
                    onTap: () => _open(i),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.stars,
    required this.locked,
    required this.onTap,
  });

  final LevelModel level;
  final int stars; // total stars of the 10 tasks
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 112,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: level.cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [BoxShadow(color: darker(level.cardColor, 0.4), offset: const Offset(0, 6))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: locked ? 0.25 : 0.5,
              child: Image.asset(
                level.background,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: ColorFiltered(
                      colorFilter: locked
                          ? const ColorFilter.mode(Colors.black54, BlendMode.srcATop)
                          : const ColorFilter.mode(Colors.transparent, BlendMode.srcATop),
                      child: Image.asset(
                        level.animalAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 50, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Level ${level.number}  -  ${level.tag}',
                            style: fancyText(15, color: Colors.white70)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(level.title, style: fancyText(26)),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 26, color: Color(0xFFFFC107)),
                            const SizedBox(width: 4),
                            Text('$stars/${kTasksPerLevel * 3}', style: fancyText(20)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    locked ? Icons.lock_rounded : Icons.play_circle_fill_rounded,
                    size: 44,
                    color: Colors.white,
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
