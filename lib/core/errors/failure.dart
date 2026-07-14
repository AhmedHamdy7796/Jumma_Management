/// Failure value objects represent expected error outcomes.
///
/// Unlike exceptions (which are thrown), failures are *returned* from
/// methods that can fail in a predictable way. They allow the caller to
/// handle the error without a try/catch.
///
/// Usage example:
/// ```dart
/// // Instead of:
/// try { ... } catch (e) { ... }
///
/// // A method can return Failure? and the caller checks:
/// final failure = await repository.doSomething();
/// if (failure != null) { showError(failure.message); }
/// ```
sealed class Failure {
  /// Arabic message safe to show in the UI.
  final String message;

  const Failure(this.message);
}

// ─────────────────────────────────────────────────────────────────────────────

/// A failure caused by a SQLite or database-layer error.
final class DatabaseFailure extends Failure {
  const DatabaseFailure([
    super.message = 'حدث خطأ في قاعدة البيانات.',
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────

/// A failure caused by invalid input data.
final class ValidationFailure extends Failure {
  /// Field-level errors. Key = field name, Value = Arabic error message.
  final Map<String, String> fieldErrors;

  ValidationFailure({
    required this.fieldErrors,
    String message = 'يوجد خطأ في البيانات المدخلة.',
  }) : super(message);
}

// ─────────────────────────────────────────────────────────────────────────────

/// A failure caused by an unexpected or unclassified error.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'حدث خطأ غير متوقع. يرجى إعادة المحاولة.',
  ]);
}
