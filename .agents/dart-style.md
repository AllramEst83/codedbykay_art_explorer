# Dart style

- Follow Effective Dart. `flutter analyze` must be clean (strict-casts, strict-inference, strict-raw-types).
- No `dynamic` outside JSON parsing; parse JSON defensively with `is`/pattern checks, never `as` on untrusted data.
- Prefer `final`, `const`, records, and `switch` expressions. Exhaustive `switch` over sealed types, no default.
- Null safety: avoid `!`; handle absence explicitly.
- Name things by intent. Comment only the non-obvious *why*; dartdoc (`///`) on public API of core/domain types.
- Imports: `package:` imports only, sorted (dart, package, then relative none).
