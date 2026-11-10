import 'package:flutter/material.dart';

import '../utils/sound_manager.dart';

/// Kid-friendly font (assets/fonts/LilitaOne-Regular.ttf, see pubspec.yaml).
const String kFont = 'LilitaOne';

TextStyle fancyText(double size, {Color color = Colors.white, double letter = 0}) {
  return TextStyle(
    fontFamily: kFont,
    fontSize: size,
    color: color,
    letterSpacing: letter,
    shadows: const [
      Shadow(color: Color(0x66000000), offset: Offset(0, 2), blurRadius: 3),
    ],
  );
}

Color alpha(Color c, double o) {
  final v = o < 0 ? 0.0 : (o > 1 ? 1.0 : o);
  return c.withAlpha((v * 255).round());
}

Color darker(Color c, [double amount = 0.3]) =>
    Color.lerp(c, Colors.black, amount) ?? c;

/// Big rounded "3D" button.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFFFB300),
    this.icon,
    this.width,
    this.fontSize = 22,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final double? width;
  final double fontSize;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        SoundManager.instance.play('click');
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: darker(widget.color, 0.35),
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: widget.fontSize + 4),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  style: fancyText(widget.fontSize),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small round icon button (pause, settings).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = const Color(0xFFFF7043),
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SoundManager.instance.play('click');
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(color: darker(color, 0.35), offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.55),
      ),
    );
  }
}

/// Rounded info pill (score, timer, level).
class HudChip extends StatelessWidget {
  const HudChip({
    super.key,
    required this.text,
    this.icon,
    this.color = Colors.white,
    this.background = const Color(0x66000000),
    this.fontSize = 18,
  });

  final String text;
  final IconData? icon;
  final Color color;
  final Color background;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: fontSize + 2),
              const SizedBox(width: 4),
            ],
            Text(text, style: fancyText(fontSize, color: color)),
          ],
        ),
      ),
    );
  }
}

/// White rounded card used by dialogs and overlays.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.accent = const Color(0xFFFFB300)});
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: accent, width: 6),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}
