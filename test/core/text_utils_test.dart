import 'package:codedbykay_art_explorer/core/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cleanCreatorName swaps surname-first and drops dates', () {
    expect(
      cleanCreatorName('Monet, Claude (1840-1926) (Artist)'),
      'Claude Monet',
    );
    expect(cleanCreatorName('Rembrandt'), 'Rembrandt');
    expect(cleanCreatorName('A, B, C'), 'A, B, C');
  });

  test('isAnonymousCreator', () {
    expect(isAnonymousCreator('Unknown'), isTrue);
    expect(isAnonymousCreator(''), isTrue);
    expect(isAnonymousCreator('Vermeer'), isFalse);
  });

  test('pickLocalized prefers lang, en, def then anything', () {
    final map = {
      'de': ['Titel'],
      'en': ['Title'],
      'def': ['x'],
    };
    expect(pickLocalized(map, lang: 'de'), ['Titel']);
    expect(pickLocalized(map, lang: 'fr'), ['Title']);
    expect(
      pickLocalized({
        'zh': ['abc'],
      }),
      ['abc'],
    );
    expect(pickLocalized('nope'), isEmpty);
  });

  test('rightsLabel', () {
    expect(
      rightsLabel('http://creativecommons.org/licenses/by-sa/4.0/'),
      'CC BY-SA 4.0',
    );
    expect(
      rightsLabel('http://creativecommons.org/publicdomain/mark/1.0/'),
      'Public Domain',
    );
    expect(
      rightsLabel('http://rightsstatements.org/vocab/InC/1.0/'),
      'In copyright',
    );
    expect(rightsLabel(null), 'Rights not stated');
  });

  test('stripHtml', () {
    expect(stripHtml('<p>Hello&nbsp;<b>world</b></p>'), 'Hello world');
  });
}
