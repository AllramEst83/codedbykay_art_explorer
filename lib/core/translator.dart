import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Translates text between languages. The UI only depends on this interface,
/// so the on-device engine can be swapped for a cloud one later.
abstract interface class Translator {
  /// Whether [from] can be translated into [to] (ISO 639-1 codes).
  bool supports(String from, String to);

  /// Translates [text]. May download a language model on first use.
  /// Throws if the model cannot be downloaded or translation fails.
  Future<String> translate(
    String text, {
    required String from,
    required String to,
  });
}

/// Google ML Kit on-device translation (Android/iOS). Models are about 30 MB
/// per language and are downloaded once, then work offline.
class MlKitTranslator implements Translator {
  // The ML Kit plugin only exists on Android and iOS.
  static bool get _platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  final _manager = OnDeviceTranslatorModelManager();
  final _cache = <String, String>{};

  @override
  bool supports(String from, String to) =>
      _platformSupported &&
      from != to &&
      BCP47Code.fromRawValue(from) != null &&
      BCP47Code.fromRawValue(to) != null;

  @override
  Future<String> translate(
    String text, {
    required String from,
    required String to,
  }) async {
    final key = '$from>$to:$text';
    final cached = _cache[key];
    if (cached != null) return cached;

    final source = BCP47Code.fromRawValue(from);
    final target = BCP47Code.fromRawValue(to);
    if (source == null || target == null) {
      throw ArgumentError('Unsupported language pair $from>$to');
    }
    for (final code in [from, to]) {
      if (!await _manager.isModelDownloaded(code) &&
          !await _manager.downloadModel(code, isWifiRequired: false)) {
        throw StateError('Could not download translation model "$code"');
      }
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
    try {
      return _cache[key] = await translator.translateText(text);
    } finally {
      await translator.close();
    }
  }
}
