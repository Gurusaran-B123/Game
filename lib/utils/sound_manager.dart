import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays sound effects and background music. Every call is wrapped in
/// try/catch, so a missing or broken audio file never crashes the game.
///
/// To use your own sounds: replace the files in assets/audio/ (same names).
class SoundManager extends ChangeNotifier {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  static const int _poolSize = 5;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  AudioPlayer? _bgm;
  String? _bgmName;
  bool _muted = false;
  bool _musicOn = true;
  bool _bgmPaused = false;
  bool _ready = false;

  bool get muted => _muted;
  bool get musicOn => _musicOn;

  Future<void> init() async {
    if (_ready) return;
    try {
      final p = await SharedPreferences.getInstance();
      _muted = p.getBool('muted') ?? false;
      _musicOn = p.getBool('music') ?? true;
    } catch (_) {}
    try {
      // Let effects and music play together without stealing audio focus.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
    } catch (e) {
      debugPrint('audio context: $e');
    }
    try {
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        _pool.add(p);
      }
      final b = AudioPlayer();
      await b.setReleaseMode(ReleaseMode.loop);
      _bgm = b;
    } catch (e) {
      debugPrint('audio init: $e');
    }
    _ready = true;
  }

  // ---- sound effects ----------------------------------------------------
  /// [name] is a file in assets/audio without ".mp3", e.g. play('pop').
  Future<void> play(String name, {double volume = 1.0}) async {
    if (_muted || !_ready || _pool.isEmpty) return;
    try {
      final p = _pool[_next];
      _next = (_next + 1) % _pool.length;
      await p.stop();
      await p.play(AssetSource('audio/$name.mp3'), volume: volume);
    } catch (e) {
      debugPrint('sfx $name: $e');
    }
  }

  // ---- music --------------------------------------------------------------
  Future<void> playMusic(String name) async {
    _bgmName = name;
    _bgmPaused = false;
    final b = _bgm;
    if (b == null) return;
    try {
      await b.stop();
      if (_wantMusic) {
        await b.play(AssetSource('audio/$name.mp3'), volume: 0.35);
      }
    } catch (e) {
      debugPrint('music $name: $e');
    }
  }

  Future<void> stopMusic() async {
    _bgmName = null;
    try {
      await _bgm?.stop();
    } catch (_) {}
  }

  Future<void> pauseMusic() async {
    _bgmPaused = true;
    await _apply();
  }

  Future<void> resumeMusic() async {
    _bgmPaused = false;
    await _apply();
  }

  bool get _wantMusic => !_muted && _musicOn && _bgmName != null && !_bgmPaused;

  Future<void> _apply() async {
    final b = _bgm;
    if (b == null) return;
    try {
      if (_wantMusic) {
        if (b.state == PlayerState.paused) {
          await b.resume();
        } else if (b.state != PlayerState.playing) {
          await b.play(AssetSource('audio/$_bgmName.mp3'), volume: 0.35);
        }
      } else if (b.state == PlayerState.playing) {
        await b.pause();
      }
    } catch (e) {
      debugPrint('music apply: $e');
    }
  }

  // ---- settings -----------------------------------------------------------
  Future<void> setMuted(bool v) async {
    _muted = v;
    notifyListeners();
    await _save();
    await _apply();
  }

  Future<void> setMusicOn(bool v) async {
    _musicOn = v;
    notifyListeners();
    await _save();
    await _apply();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool('muted', _muted);
      await p.setBool('music', _musicOn);
    } catch (_) {}
  }
}
