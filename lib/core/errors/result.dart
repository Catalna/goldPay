/// Expected failures are values, not exceptions (docs/03 §4).
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// A failure carries a stable code that maps to copy in `CopyId`.
/// Never render [detailForDev] to users.
class Failure {
  const Failure(this.code, {this.detailForDev});

  final String code;
  final String? detailForDev;

  @override
  String toString() => 'Failure($code)';
}
