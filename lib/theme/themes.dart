import 'package:flutter/material.dart';

/// Memova's theme — 黛绿 (dài lǜ, muted deep green, #3B7A57) as the seed.
///
/// - Color: MD3 `tonalSpot` keeps 黛绿's restrained ink-green character
///   (light primary #296A48 / dark #92D5AB); the deep-grey-green washes the
///   surfaces faintly green.
/// - Error: Material's default error red is replaced by the 朱红 (vermilion)
///   family, re-toned to Material's error role structure (light: error tone
///   40, container tone 90; dark: tone 80 / 30) so contrast stays intact.
ThemeData memovaTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B7A57), // 黛绿
    brightness: brightness,
  );

  const vermilionErrorLight = Color(0xFFBC3510); // 朱红 tone 40
  const vermilionContainerLight = Color(0xFFFBD9D0); // tone 90
  const vermilionOnContainerLight = Color(0xFF8D280C); // tone 30-ish

  const vermilionErrorDark = Color(0xFFF7B3A1); // 朱红 tone 80
  const vermilionContainerDark = Color(0xFF8D280C); // tone 30
  const vermilionOnErrorDark = Color(0xFF330E0B); // tone 15-ish
  const vermilionOnContainerDark = Color(0xFFFBD9D0); // tone 90

  final colorScheme = scheme.copyWith(
    error: brightness == Brightness.light
        ? vermilionErrorLight
        : vermilionErrorDark,
    onError: brightness == Brightness.light
        ? Colors.white
        : vermilionOnErrorDark,
    errorContainer: brightness == Brightness.light
        ? vermilionContainerLight
        : vermilionContainerDark,
    onErrorContainer: brightness == Brightness.light
        ? vermilionOnContainerLight
        : vermilionOnContainerDark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    // Modern M3 touch: the undo snackbar floats above the list instead of
    // pinning to the bottom edge.
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
