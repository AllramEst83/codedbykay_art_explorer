# Art Explorer — Build Plan

Android-only Flutter app for browsing, reading about, and learning from art. Europeana is the first source; the data layer is built so more art APIs can be added as modules.

Starting state: stock `flutter create` scaffold (Flutter 3.47, Dart ^3.13), empty `.agents/`, API key in `.env` as `api-key=...`.

## Decisions to confirm early

| Topic | Proposal | Why |
|---|---|---|
| State management | Riverpod (`flutter_riverpod` + `riverpod_annotation`) | Testable, compile-safe DI; fits the layered architecture |
| Navigation | `go_router` | Deep links, typed routes, bottom-nav shell |
| HTTP | `dio` (interceptor adds `X-Api-Key`, retry, cache) | Interceptors keep the key out of call sites |
| Local storage | `drift` (SQLite) for bookmarks/history; `shared_preferences` for reader prefs | Bookmarks need querying/offline; prefs are key-value |
| Models | `freezed` + `json_serializable` | Immutable, exhaustive unions for loading/error states |
| Images | `cached_network_image` + `photo_view` | Disk cache; pinch-zoom for artwork |
| API key | Bundle `.env` as an asset and load it at startup with `flutter_dotenv` | The app is for private use only, so the key can live in the app. `.env` stays git-ignored; no proxy or obfuscation needed |

Note: `.env` is currently **not** in `.gitignore`. Add it before any `git init`/commit.

## Phase 0 — Rules and project setup

1. Write `.agents/` Flutter rules (the "best practices" request). Proposed files:
   - `flutter-architecture.md` — layers (UI / domain / data), feature-first folders, dependency direction, repository pattern.
   - `dart-style.md` — Effective Dart, strict analysis, null safety, sealed classes/pattern matching, no `dynamic`, const everywhere possible.
   - `state-and-async.md` — Riverpod conventions, `AsyncValue` handling, cancellation, no `BuildContext` across async gaps.
   - `ui-and-performance.md` — small widgets over helper methods, `const`, slivers/lazy lists, image sizing/caching, `RepaintBoundary` only when profiled.
   - `accessibility-and-theming.md` — Material 3, light/dark, 48dp targets, semantics labels, text scaling, contrast.
   - `networking-and-errors.md` — typed `Result`/failure types, timeouts, retries, never leak raw exceptions to UI.
   - `testing.md` — unit (repos, mappers), widget (golden for key screens), integration; fakes over mocks; coverage targets.
   - `security-and-secrets.md` — key handling, no logging of keys, network security config, R8/obfuscation for release.
   - `git-and-ci.md` — commit conventions, `flutter analyze` + `flutter test` gate.
2. Tighten `analysis_options.yaml` (`strict-casts`, `strict-inference`, `strict-raw-types`, extra lint set).
3. Update the Android app id to `codedbykay_art_explorer` (`applicationId` and `namespace` in `android/app/build.gradle*`, plus the `MainActivity` package/directory and manifest references). Also set the app name, `minSdk`, adaptive icon and splash. Only `android/` exists, so no other platforms need removing.
   - **Caveat:** Android requires an application id with at least two dot-separated segments, so a single-segment id like `codedbykay_art_explorer` will fail to build or be rejected by Google Play. Options: `com.codedbykay.art_explorer` (recommended), or `codedbykay.art_explorer`. The plan uses your exact id until you confirm; the id cannot be changed after the first Play Store release.
4. Add dependencies; set up `build_runner`.
5. Create folder skeleton:

```
lib/
  main.dart
  app/                    # MaterialApp.router, theme, router, DI root
  core/                   # network, errors, result, storage, utils, widgets
  features/
    search/   (data|domain|presentation)
    artwork/  (detail, viewer)
    reader/
    bookmarks/
    explore/
    settings/
  sources/                # art-source modules
    art_source.dart       # abstract interface
    europeana/            # client, DTOs, mappers
```

**Done when:** app boots to an empty shell, `flutter analyze` is clean, CI script passes.

## Phase 1 — Data layer and the multi-source abstraction

Define a source-agnostic domain model so Europeana is just one implementation.

- `Artwork` (id, source, title, creators, date, description(s), thumbnail/image URLs, media type, rights/license, provider, original-record URL, language, subjects).
- `abstract interface class ArtSource { id, displayName; Future<Result<Page<Artwork>>> search(SearchQuery); Future<Result<ArtworkDetail>> getArtwork(String id); Future<Result<List<Artwork>>> related(String id); }`
- `ArtSourceRegistry` provided via Riverpod; UI only talks to repositories that fan out over registered sources.

Europeana module (`sources/europeana/`):

- **Search API** `GET https://api.europeana.eu/record/v2/search.json` — `query`, `qf` (filters: `TYPE:IMAGE`, `MEDIA:true`, `THUMBNAIL:true`, `REUSABILITY:open`), `rows`, `cursor` pagination (`*` then `nextCursor`), `profile=standard`, facets (`TYPE`, `YEAR`, `COUNTRY`, `PROVIDER`).
- **Record API** `GET /record/v2/{datasetId}/{localId}.json` — full metadata, `edmIsShownBy` (full image), aggregations, rights.
- **Recommend / similar items** for "related artwork".
- **Entity API** (creator/period/concept pages and biographies) — feeds the reader and "explore".
- **IIIF** (where a manifest exists) for deep-zoom images.
- Thumbnail via `edmPreview` / Thumbnail API (needs no key).
- DTO → domain mappers, with defensive handling: fields are frequently missing, multilingual maps (`{"def": [...], "en": [...]}`), or arrays; pick the best language by device locale with fallback.
- Dio interceptor injects `X-Api-Key`; response cache (short TTL) and rate-limit/429 backoff.

I will pull the exact request/response shapes from the Search and Record API docs linked in `api.md` before coding this phase, and save real sample JSON under `test/fixtures/europeana/` for tests.

**Done when:** repository unit tests pass against fixtures, and a throwaway screen prints live search results.

## Phase 2 — Search and browse (core feature 1)

- Home/Search screen: search bar with debounce, recent searches, suggested queries ("Impressionism", "Rembrandt", "Ukiyo-e").
- Results as a lazy masonry/staggered grid (thumbnails sized for the viewport), infinite scroll via cursor.
- Filter sheet: type (image only by default), century/year range, country, provider, open-license only; sort relevance.
- States: loading skeleton, empty, offline, error with retry, rate-limited.
- Hero transition from grid tile to detail.

## Phase 3 — Artwork detail and viewer (feature 2)

- Detail screen: large image, title, creator (tappable → explore), date, medium/type, provider, rights badge, source link.
- Full-screen viewer: pinch-zoom/pan, double-tap zoom, immersive mode; deep zoom via IIIF where available.
- Actions: bookmark, share (link + attribution), open original record, open reader.
- Attribution/licensing shown correctly (required for Europeana reuse).

## Phase 4 — Reader mode (feature 3)

Content for reading is assembled from: record description(s), creator/period/concept bios from the Entity API, and full text where the Fulltext API has it. Descriptions are often short or non-English, so the reader merges and clearly labels each section and its source. A language fallback chain is applied.

Controls (bottom sheet, persisted via `shared_preferences`, applied live):

- Background theme: 3 options — **Paper** (warm off-white), **Sepia**, **Night** (dark) — with matching text colors that meet WCAG AA contrast.
- Font size slider (e.g. 14–32 sp, respecting system text scale).
- Font family selector: 3–4 bundled/Google Fonts options (serif such as Merriweather/Lora, sans such as Inter/Atkinson Hyperlegible, and a dyslexia-friendly option). Bundle the fonts as assets so reading works offline.

Additional essentials I recommend:

- Line-height and margin/width control (compact stepper next to size).
- Reading progress indicator and scroll-position restore per artwork.
- Keep-screen-on while reading (`wakelock_plus`).
- Text selection and copy; share quote.
- Text-to-speech read-aloud (`flutter_tts`), a good fit for an educational app.
- Translate hint when the text language differs from the device language (link out; no bundled translation in v1).
- Tap-to-toggle chrome (immersive reading).

## Phase 5 — Bookmarks (feature 4)

- Drift tables: `bookmarks` (artwork snapshot JSON, source, createdAt), optional `collections` and join table.
- Save a snapshot of the metadata plus the thumbnail URL so bookmarks open offline (image from the disk cache).
- Bookmarks screen: grid/list toggle, search within bookmarks, sort, swipe-to-remove with undo, optional named collections.
- Export/share the list as text (stretch).

## Phase 6 — Natural exploration (feature 5)

"Naturally explore" is read as: discovery without having to type a query.

- **Discover feed**: curated seed queries (movements, artists, themes, regions), randomized per session, to avoid repeats.
- **Related artwork**: "More like this" from the Recommend API and shared creator/subject.
- **Creator and period pages** from the Entity API: bio, timeline, works.
- **Browse by**: movement, medium, country, century, color (Europeana supports color filtering for images — verify in docs).
- **Surprise me** button for a random artwork.
- **Artwork of the day** (deterministic by date; cached) with an optional notification (stretch).
- Continue-exploring trail: breadcrumb of the path taken (Artwork → Artist → Related).

## Phase 7 — UX polish and extra features

- Material 3 theme with dynamic color on Android 12+, light/dark/system.
- Bottom navigation: **Discover · Search · Bookmarks · Settings**.
- Settings: theme, default reader prefs, clear image cache, source toggles (for future modules), licensing/attribution page, about.
- History of recently viewed items.
- Offline: cached results, bookmarks, and a clear offline banner.
- Accessibility pass: TalkBack labels, text scaling to 200%, contrast, focus order.
- Localization scaffolding (`flutter_localizations`, ARB) with English first.
- Edge-to-edge, predictive back (Android 14+), adaptive layouts for tablets and foldables.
- Performance: image `cacheWidth`, list virtualization, profile on a mid-range device.

## Phase 8 — Testing, hardening, release

- Unit: mappers (with messy fixtures), repositories, reader-prefs controller.
- Widget: search states, reader controls, bookmark toggle; golden tests for the reader themes.
- Integration: search → open → read → bookmark → relaunch → bookmark persists (`integration_test`).
- Error handling: airplane mode, 429, malformed records, missing images.
- Release: R8/minify, `--obfuscate --split-debug-info`, signing config, app bundle, privacy policy (no personal data collected; only the Europeana API is called), store listing assets.

## Milestones

| # | Milestone | Phases |
|---|---|---|
| M1 | Skeleton, rules, CI | 0 |
| M2 | Live search + detail | 1–3 |
| M3 | Reader + bookmarks | 4–5 |
| M4 | Explore + polish | 6–7 |
| M5 | Release candidate | 8 |

## Risks and open questions

- **Sparse text for the reader.** Many Europeana records have only a one-line description. Entity bios mitigate this; a Wikipedia/Wikidata module could be the second source. Which would you like as the second source?
- **Rights.** Not everything is openly reusable; default to open-license filter and always show attribution.
- **Rate limits** on the key — add caching and debounce early.
- **Key exposure:** accepted, since the app is private. Never commit `.env`; do not publish the APK publicly.

## Suggested first step

Phase 0, item 1: write the `.agents/` rule files, then scaffold and wire up the Europeana client once you approve the stack choices above.

## Status and deviations (as built)

All phases are implemented. Deviations from the plan above:

- **Storage:** bookmarks, history and reader prefs use `shared_preferences` (JSON), not drift. No code generation is used (no freezed/json_serializable/riverpod_annotation).
- **App id:** `com.codedbykay.art_explorer`, because Android rejects single-segment ids.
- **Grid:** fixed-ratio tiles rather than masonry.
- **Related works:** found by creator search, not the Recommend API (it returned 401 with the header key).
- **IIIF deep zoom** and the "artwork of the day" notification were not built; the viewer uses the full image with pinch-zoom.
- **Fonts:** loaded through `google_fonts` at runtime and cached, not bundled.
- **Biographies:** Wikipedia summaries are used in addition to the Entity API.
- **Languages:** English and Swedish (`lib/l10n/*.arb`), switchable in Settings; remote content is requested in the chosen language.
