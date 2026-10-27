import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads configuration from the bundled `.env` (private-use app).
abstract final class Env {
  static Future<void> load() => dotenv.load();

  static String get europeanaKey => dotenv.maybeGet('api-key') ?? '';
}
