/// Outcome of a repository call. Exceptions never cross this boundary.
sealed class Result<T> {
  const Result();

  /// Returns the value, or null when this is an [Err].
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  R when<R>({
    required R Function(T value) ok,
    required R Function(Failure failure) err,
  }) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Err<T>(:final failure) => err(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure()
    : super('No connection. Check your network and retry.');
}

final class RateLimitFailure extends Failure {
  const RateLimitFailure()
    : super('Too many requests. Please wait a moment and retry.');
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure() : super('Nothing found.');
}

final class ParseFailure extends Failure {
  const ParseFailure() : super('The server sent data we could not read.');
}

final class UnknownFailure extends Failure {
  const UnknownFailure() : super('Something went wrong. Please retry.');
}
