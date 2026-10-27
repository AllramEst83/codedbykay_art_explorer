import 'package:codedbykay_art_explorer/core/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

enum ReaderTheme {
  paper('Paper', Color(0xFFFAF7F0), Color(0xFF222222)),
  sepia('Sepia', Color(0xFFF1E4C8), Color(0xFF4A3524)),
  night('Night', Color(0xFF121212), Color(0xFFD8D8D8));

  const ReaderTheme(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;
}

enum ReaderFont {
  lora('Lora (serif)'),
  merriweather('Merriweather (serif)'),
  inter('Inter (sans)'),
  atkinson('Atkinson Hyperlegible');

  const ReaderFont(this.label);
  final String label;

  TextStyle style() {
    try {
      return switch (this) {
        lora => GoogleFonts.lora(),
        merriweather => GoogleFonts.merriweather(),
        inter => GoogleFonts.inter(),
        atkinson => GoogleFonts.atkinsonHyperlegible(),
      };
    } on Object {
      return const TextStyle();
    }
  }
}

class ReaderPrefs {
  const ReaderPrefs({
    this.theme = ReaderTheme.paper,
    this.font = ReaderFont.lora,
    this.fontSize = 18,
    this.lineHeight = 1.6,
    this.margin = 20,
  });

  static const minFontSize = 14.0;
  static const maxFontSize = 32.0;

  final ReaderTheme theme;
  final ReaderFont font;
  final double fontSize;
  final double lineHeight;
  final double margin;

  ReaderPrefs copyWith({
    ReaderTheme? theme,
    ReaderFont? font,
    double? fontSize,
    double? lineHeight,
    double? margin,
  }) => ReaderPrefs(
    theme: theme ?? this.theme,
    font: font ?? this.font,
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    margin: margin ?? this.margin,
  );
}

/// Persisted reader preferences, applied live.
class ReaderPrefsController extends Notifier<ReaderPrefs> {
  static const _kTheme = 'reader.theme';
  static const _kFont = 'reader.font';
  static const _kSize = 'reader.size';
  static const _kLine = 'reader.line';
  static const _kMargin = 'reader.margin';

  @override
  ReaderPrefs build() {
    final p = ref.watch(sharedPreferencesProvider);
    return ReaderPrefs(
      theme:
          ReaderTheme.values.asNameMap()[p.getString(_kTheme)] ??
          ReaderTheme.paper,
      font:
          ReaderFont.values.asNameMap()[p.getString(_kFont)] ?? ReaderFont.lora,
      fontSize: (p.getDouble(_kSize) ?? 18).clamp(
        ReaderPrefs.minFontSize,
        ReaderPrefs.maxFontSize,
      ),
      lineHeight: (p.getDouble(_kLine) ?? 1.6).clamp(1.2, 2.2),
      margin: (p.getDouble(_kMargin) ?? 20).clamp(8, 48),
    );
  }

  void update(ReaderPrefs prefs) {
    state = prefs;
    final p = ref.read(sharedPreferencesProvider);
    p
      ..setString(_kTheme, prefs.theme.name)
      ..setString(_kFont, prefs.font.name)
      ..setDouble(_kSize, prefs.fontSize)
      ..setDouble(_kLine, prefs.lineHeight)
      ..setDouble(_kMargin, prefs.margin);
  }
}

final readerPrefsProvider =
    NotifierProvider<ReaderPrefsController, ReaderPrefs>(
      ReaderPrefsController.new,
    );

/// Selected app language; null follows the system language.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'app.locale';
  static const supported = ['en', 'sv'];

  @override
  Locale? build() {
    final code = ref.watch(sharedPreferencesProvider).getString(_key);
    return supported.contains(code) ? Locale(code!) : null;
  }

  void set(Locale? locale) {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      prefs.remove(_key);
    } else {
      prefs.setString(_key, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'app.themeMode';

  @override
  ThemeMode build() {
    final name = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.asNameMap()[name] ?? ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
