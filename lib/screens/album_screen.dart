import 'package:flutter/material.dart';

import '../models/level_model.dart';
import '../utils/progress_store.dart';
import '../widgets/ui_bits.dart';

/// Collection book: every baby you have hatched. Unfound babies are black shapes.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  Set<String> _found = {};

  @override
  void initState() {
    super.initState();
    ProgressStore.album().then((v) {
      if (mounted) setState(() => _found = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF59D), Color(0xFF81D4FA)],
          ),
        ),
        child: SafeArea(
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('My Babies', style: fancyText(34, color: const Color(0xFFEF6C00))),
                    ),
                    HudChip(
                      icon: Icons.egg_alt_rounded,
                      text: '${_found.length}/${kLevels.length}',
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.all(18),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                  children: [
                    for (final l in kLevels) _card(l, _found.contains(l.babyName)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(LevelModel l, bool found) {
    return Container(
      decoration: BoxDecoration(
        color: found ? l.cardColor : const Color(0xFF9E9E9E),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [BoxShadow(color: darker(found ? l.cardColor : const Color(0xFF9E9E9E), 0.4), offset: const Offset(0, 5))],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: ColorFiltered(
              colorFilter: found
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.srcATop)
                  : const ColorFilter.mode(Colors.black87, BlendMode.srcATop),
              child: Image.asset(
                l.animalAsset,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 60, color: Colors.white),
              ),
            ),
          ),
          Text(found ? l.babyName : '???', style: fancyText(22)),
          Text(found ? l.homeName : 'Not hatched yet', style: fancyText(13, color: Colors.white70)),
        ],
      ),
    );
  }
}
