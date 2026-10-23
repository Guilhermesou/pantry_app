import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

/// Haptics with meaning: each kind of moment has its own feel, like a game.
abstract final class Haptics {
  // Widget tests fail on pending timers, so patterns there keep only the first beat.
  static final _patterns = !Platform.environment.containsKey('FLUTTER_TEST');

  /// Choosing, toggling, stepping a value.
  static void tap() => HapticFeedback.selectionClick();

  /// Pressing a main action.
  static void press() => HapticFeedback.lightImpact();

  /// Something worked: a quick light-then-firm double beat.
  static void success() =>
      _pattern([HapticFeedback.lightImpact, HapticFeedback.mediumImpact], 90);

  /// "Not this": two firm knocks, paired with a shake on screen.
  static void error() =>
      _pattern([HapticFeedback.heavyImpact, HapticFeedback.heavyImpact], 120);

  /// A finished milestone: a rising light, medium, heavy roll.
  static void celebrate() => _pattern([
    HapticFeedback.lightImpact,
    HapticFeedback.mediumImpact,
    HapticFeedback.heavyImpact,
  ], 85);

  static void _pattern(List<Future<void> Function()> beats, int gap) {
    beats.first();
    if (!_patterns) return;
    for (var i = 1; i < beats.length; i++) {
      Timer(Duration(milliseconds: gap * i), beats[i]);
    }
  }
}
