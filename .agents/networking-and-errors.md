# Networking and errors

- One configured `Dio` per source with timeouts, an interceptor for the API key header, and retry/backoff on 429/5xx/timeouts.
- Repositories return `Result<T>` (`Ok`/`Err`) with a sealed `Failure` (network, rate-limit, not-found, parse, unknown). Exceptions do not reach the UI.
- UI maps `Failure` to friendly text with a retry action.
- Never log request headers or the API key.
- Treat all remote data as untrusted and optional; tolerate missing fields and multilingual maps.
