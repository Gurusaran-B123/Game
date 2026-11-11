import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/sound_manager.dart';
import 'ui_bits.dart';

/// Dark background behind a dialog-style overlay.
class _Scrim extends StatelessWidget {
  const _Scrim({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x99000000),
      alignment: Alignment.center,
      child: SingleChildScrollView(child: child),
    );
  }
}

/// Mute / music switches. Used from the level screen and from the game.
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final sm = SoundManager.instance;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ListenableBuilder(
        listenable: sm,
        builder: (context, _) => Panel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Settings', style: fancyText(32, color: const Color(0xFFEF6C00))),
              const SizedBox(height: 14),
              _row(
                icon: sm.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                label: sm.muted ? 'Sound: Muted' : 'Sound: On',
                value: !sm.muted,
                onChanged: (v) => sm.setMuted(!v),
              ),
              _row(
                icon: sm.musicOn ? Icons.music_note_rounded : Icons.music_off_rounded,
                label: sm.musicOn ? 'Music: On' : 'Music: Off',
                value: sm.musicOn,
                onChanged: (v) => sm.setMusicOn(v),
              ),
              const SizedBox(height: 14),
              ChunkyButton(
                label: 'Done',
                icon: Icons.check_rounded,
                color: const Color(0xFF43A047),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFEF6C00), size: 30),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: fancyText(20, color: const Color(0xFF5D4037)))),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF43A047)),
        ],
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onSettings,
    required this.onMenu,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSettings;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return _Scrim(
      child: Panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paused', style: fancyText(36, color: const Color(0xFFEF6C00))),
            const SizedBox(height: 16),
            ChunkyButton(label: 'Resume', icon: Icons.play_arrow_rounded, color: const Color(0xFF43A047), width: 230, onTap: onResume),
            const SizedBox(height: 12),
            ChunkyButton(label: 'Restart', icon: Icons.replay_rounded, color: const Color(0xFF1E88E5), width: 230, onTap: onRestart),
            const SizedBox(height: 12),
            ChunkyButton(label: 'Settings', icon: Icons.settings_rounded, color: const Color(0xFF8E24AA), width: 230, onTap: onSettings),
            const SizedBox(height: 12),
            ChunkyButton(label: 'Levels', icon: Icons.grid_view_rounded, color: const Color(0xFFEF5350), width: 230, onTap: onMenu),
          ],
        ),
      ),
    );
  }
}

/// Three stars that pop in one after another.
class StarRow extends StatefulWidget {
  const StarRow({super.key, required this.count});
  final int count;

  @override
  State<StarRow> createState() => _StarRowState();
}

class _StarRowState extends State<StarRow> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  int _played = 0;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() {
      final shown = math.min(widget.count, (_ctl.value * 3 / 0.9).floor());
      if (shown > _played) {
        _played = shown;
        SoundManager.instance.play('star');
      }
    });
    _ctl.forward();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Builder(builder: (context) {
                final earned = i < widget.count;
                final local = ((_ctl.value * 3 / 0.9) - i).clamp(0.0, 1.0);
                final s = earned ? Curves.elasticOut.transform(local) : 1.0;
                return Transform.scale(
                  scale: 0.2 + 0.8 * s,
                  child: Transform.rotate(
                    angle: (i - 1) * 0.15,
                    child: Icon(
                      Icons.star_rounded,
                      size: i == 1 ? 84 : 66,
                      color: earned ? const Color(0xFFFFC107) : const Color(0xFFBCAAA4),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class LevelCompleteOverlay extends StatelessWidget {
  const LevelCompleteOverlay({
    super.key,
    required this.stars,
    required this.score,
    required this.timeLeft,
    required this.isLast,
    required this.onNext,
    required this.onReplay,
    required this.onMenu,
  });

  final int stars;
  final int score;
  final int timeLeft;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return _Scrim(
      child: Panel(
        accent: const Color(0xFF43A047),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              child: Text('Level Complete!', style: fancyText(36, color: const Color(0xFF2E7D32))),
            ),
            const SizedBox(height: 6),
            StarRow(count: stars),
            const SizedBox(height: 4),
            Text('Score: $score', style: fancyText(26, color: const Color(0xFF5D4037))),
            Text('Time left: ${timeLeft}s', style: fancyText(18, color: const Color(0xFF8D6E63))),
            const SizedBox(height: 16),
            if (!isLast)
              ChunkyButton(label: 'Next Level', icon: Icons.arrow_forward_rounded, color: const Color(0xFF43A047), width: 240, onTap: onNext)
            else
              Text('You hatched them all!', style: fancyText(22, color: const Color(0xFFEF6C00))),
            const SizedBox(height: 12),
            ChunkyButton(label: 'Play Again', icon: Icons.replay_rounded, color: const Color(0xFF1E88E5), width: 240, onTap: onReplay),
            const SizedBox(height: 12),
            ChunkyButton(label: 'Levels', icon: Icons.grid_view_rounded, color: const Color(0xFFEF5350), width: 240, onTap: onMenu),
          ],
        ),
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({super.key, required this.score, required this.reason, required this.onRetry, required this.onMenu});
  final int score;
  final String reason;
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return _Scrim(
      child: Panel(
        accent: const Color(0xFFEF5350),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Game Over', style: fancyText(38, color: const Color(0xFFD32F2F))),
            const SizedBox(height: 6),
            const Icon(Icons.alarm_off_rounded, size: 70, color: Color(0xFFEF5350)),
            Text(reason, textAlign: TextAlign.center, style: fancyText(22, color: const Color(0xFF8D6E63))),
            Text('Score: $score', style: fancyText(24, color: const Color(0xFF5D4037))),
            const SizedBox(height: 16),
            ChunkyButton(label: 'Retry', icon: Icons.replay_rounded, color: const Color(0xFF43A047), width: 230, onTap: onRetry),
            const SizedBox(height: 12),
            ChunkyButton(label: 'Levels', icon: Icons.grid_view_rounded, color: const Color(0xFFEF5350), width: 230, onTap: onMenu),
          ],
        ),
      ),
    );
  }
}
