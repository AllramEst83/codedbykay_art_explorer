# Art Explorer

An Android app for browsing, reading about and exploring art. Artwork comes from the [Europeana](https://www.europeana.eu/) APIs; the code is structured so more art sources can be added later.

Private-use app. It is not intended for publication (see [API key](#api-key)).

## Features

- **Search** artwork with filters for year range, country and open licence. Infinite scroll, recent searches.
- **Artwork detail** with rights and attribution, share, a pinch-zoom full-screen viewer, and "more like this".
- **Reader mode** for the text about a work and its artist:
  - three backgrounds (Paper, Sepia, Night)
  - font size slider, font selector, line spacing and margins
  - read aloud, keep screen on, text selection, scroll position remembered
- **Bookmarks** that open offline, with sort, search, collections, swipe to remove and undo.
- **Discover**: artwork of the day, a "More <subject>" row, "surprise me" and recently viewed. The daily pick and "surprise me" are drawn from the subjects Europeana reports, so there are no hand-written lists. Below those are live categories taken from the Europeana API, each with a "See all" list:
  - subjects and techniques (named in your language)
  - time periods (centuries and decades)
  - countries
  - museums and collections
  - colours
- **Category pages** have their own search box and filters, so you can narrow a category further.
- **Smart search box**: typing `cubism 1900s france` turns the year and country into filter chips.
- **Creator pages** with a biography and their works.
- **Languages**: English and Swedish, switchable in Settings. Europeana and Wikipedia content is requested in the chosen language.
- Material 3 with light, dark and system themes, and Material You colours on Android 12+.

## Data sources

| Source | Used for |
|---|---|
| Europeana Search and Record APIs | Search results, artwork metadata and images, and the facet counts behind the Discover categories |
| Europeana Entity API | Artist short description and dates, and names for subject categories |
| Wikipedia REST API | Artist biography and portrait (CC BY-SA); no key needed |

Each artwork shows its own rights statement. Not everything in Europeana is openly reusable, and the Discover rows only show openly licensed works.

## Getting started

Requirements: Flutter (Dart `^3.13`), the Android SDK with licences accepted (`flutter doctor --android-licenses`), and a device or emulator.

```
flutter pub get
flutter run
```

### API key

Create a `.env` file in the project root with your Europeana key:

```
api-key=YOUR_EUROPEANA_KEY
```

`.env` is git-ignored but **bundled into the app as an asset**, so anyone with the APK can read the key. That is acceptable for private use; do not publish the app or commit the file.

## Project structure

```
lib/
  app/            App widget, router, theme, bottom-navigation shell
  core/           Result/Failure types, env, providers, shared widgets
  features/       search, artwork, reader, bookmarks, explore, history, settings
  l10n/           ARB files (en, sv) and generated localizations
  sources/        ArtSource interface and provider modules
    europeana/    API client, JSON mapper
    wikipedia/    Biography client
test/             Unit and widget tests, with real Europeana JSON in fixtures/
tool/             Icon generator
.agents/          Flutter development rules for this project
```

The data layer is source-agnostic: UI depends only on the `ArtSource` interface and domain models (`Artwork`, `ArtworkDetail`, `CreatorProfile`). To add a provider, implement `ArtSource` under `lib/sources/<name>/` and register it in `artSourcesProvider` (`lib/core/providers.dart`).

Built with Riverpod, go_router, Dio, cached_network_image and photo_view. Bookmarks, history and reader preferences are stored with `shared_preferences`.

## Development

```
flutter analyze
flutter test
```

- Rules for architecture, style, state, UI, accessibility, networking, testing and secrets are in [`.agents/`](.agents/).
- Strings live in `lib/l10n/app_en.arb` and `app_sv.arb`. After editing them, run `flutter gen-l10n`.
- App icon: edit `assets/icon/icon.png`, then run:
  ```
  python tool/generate_icons.py
  dart run flutter_launcher_icons
  ```
  The generator needs Python with Pillow.

## Notes

- Application id: `com.codedbykay.art_explorer`.
- Reader fonts (Lora, Merriweather, Inter, Atkinson Hyperlegible) are downloaded on first use through `google_fonts`, then cached.
- Not built: IIIF deep zoom and the artwork-of-the-day notification. See [BUILD_PLAN.md](BUILD_PLAN.md) for the original plan and the deviations from it.
