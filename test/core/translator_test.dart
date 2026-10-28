import 'package:codedbykay_art_explorer/core/translator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final translator = MlKitTranslator();

  test('supports Europeana languages into Swedish and English', () {
    expect(translator.supports('de', 'sv'), isTrue);
    expect(translator.supports('nl', 'en'), isTrue);
    expect(translator.supports('en', 'sv'), isTrue);
  });

  test('does not support same, unknown or unmapped languages', () {
    expect(translator.supports('sv', 'sv'), isFalse);
    expect(translator.supports('xx', 'sv'), isFalse);
    expect(translator.supports('de', 'zz'), isFalse);
  });
}
