# Testing

- Unit tests for mappers (real JSON fixtures in `test/fixtures`), repositories, controllers.
- Widget tests for screens' loading/empty/error/data states and reader controls.
- Prefer hand-written fakes over mocks; use `mocktail` only for HTTP boundaries.
- Override Riverpod providers in tests; no real network or real disk in unit/widget tests.
- Gate: `flutter analyze` and `flutter test` must pass before commit.
