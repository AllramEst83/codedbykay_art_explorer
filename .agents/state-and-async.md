# State and async

- Riverpod 3: `Notifier`/`AsyncNotifier` for state, `Provider`/`FutureProvider` for derived values. Keep providers top-level and named `<thing>Provider`.
- Render `AsyncValue` with `.when`/pattern matching including loading, error (with retry) and empty states.
- Never use `BuildContext` after an `await` without checking `context.mounted`.
- Debounce user-typed queries; cancel or ignore stale responses (compare request token before applying).
- Dispose controllers, focus nodes, subscriptions and TTS/wakelock in `dispose`.
- Side effects (navigation, snackbars) happen in UI listeners, not in notifiers.
