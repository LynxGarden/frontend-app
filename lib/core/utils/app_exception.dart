/// Base exception for repository/service errors that should surface a
/// friendly message to the user via `AppToast.show()`.
///
/// Convention: repositories catch raw Supabase/HTTP errors, wrap them in
/// an [AppException] with a user-friendly [message], and rethrow. The UI
/// layer only ever shows [message] — never the raw backend error.
///
/// ```dart
/// try {
///   await SupabaseClientWrapper.db('profiles').update({...});
/// } catch (e) {
///   throw AppException('Could not save your changes. Please try again.', cause: e);
/// }
/// ```
class AppException implements Exception {
  AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message${cause != null ? ' (cause: $cause)' : ''}';

  /// Extracts a friendly message from a raw JSON error body, falling back
  /// through common key names (`message`, `error`, `error_description`)
  /// before giving up and using [fallback].
  static String extractMessage(Object error, {String fallback = 'Something went wrong.'}) {
    if (error is Map) {
      for (final key in ['message', 'error', 'error_description']) {
        final value = error[key];
        if (value is String && value.isNotEmpty) return value;
      }
    }
    return fallback;
  }
}
