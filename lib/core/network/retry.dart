/// Retries [action] with exponential backoff. Rethrows the last error if
/// every attempt fails.
Future<T> withRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 4,
  Duration initialDelay = const Duration(seconds: 2),
}) async {
  var attempt = 0;
  var delay = initialDelay;

  while (true) {
    attempt++;
    try {
      return await action();
    } catch (e) {
      if (attempt >= maxAttempts) rethrow;
      await Future.delayed(delay);
      delay *= 2;
    }
  }
}
