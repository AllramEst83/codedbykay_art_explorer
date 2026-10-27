import 'package:flutter/material.dart';
import 'package:material_ui/material_ui.dart' as mui;

const _seed = Color(0xFF8B5E3C);

/// Converts the platform (Material You) scheme from `dynamic_color`.
ColorScheme? fromDynamic(mui.ColorScheme? s, Brightness brightness) => s == null
    ? null
    : ColorScheme.fromSeed(
        seedColor: s.primary,
        brightness: brightness,
      ).copyWith(
        primary: s.primary,
        onPrimary: s.onPrimary,
        primaryContainer: s.primaryContainer,
        onPrimaryContainer: s.onPrimaryContainer,
        secondary: s.secondary,
        onSecondary: s.onSecondary,
        secondaryContainer: s.secondaryContainer,
        onSecondaryContainer: s.onSecondaryContainer,
        tertiary: s.tertiary,
        onTertiary: s.onTertiary,
        surface: s.surface,
        onSurface: s.onSurface,
        error: s.error,
        onError: s.onError,
      );

ThemeData buildTheme(Brightness brightness, {ColorScheme? dynamicScheme}) {
  final scheme =
      dynamicScheme ??
      ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      },
    ),
  );
}
