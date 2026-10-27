# Architecture

- Feature-first folders: `lib/features/<feature>/{data,domain,presentation}`. Shared code lives in `lib/core`, art providers in `lib/sources/<name>`.
- Dependency direction: presentation -> domain <- data. Domain is pure Dart (no Flutter, no Dio, no storage).
- UI never calls an API or storage directly; it reads Riverpod providers that expose repositories/controllers.
- Each art API implements `ArtSource` and returns domain models (`Artwork`, `ArtworkDetail`). DTOs and JSON shapes never leave `lib/sources/<name>`.
- Prefer small immutable classes with `const` constructors. Use `sealed` classes and pattern matching for variants.
- One public type per file where practical; no barrel files that hide dependencies.
- Constructor-inject dependencies; override providers in tests instead of using globals/singletons.
