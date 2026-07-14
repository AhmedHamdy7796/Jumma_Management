/// Base class for all application exceptions.
///
/// Every exception carries two messages:
/// - [userMessage]: A friendly Arabic message shown in the UI.
/// - [technicalDetail]: The full technical description written to the log file.
abstract class AppException implements Exception {
  /// User-facing Arabic message. Safe to show in dialogs.
  final String userMessage;

  /// Technical detail for log files. Never shown in the UI.
  final String technicalDetail;

  const AppException({
    required this.userMessage,
    required this.technicalDetail,
  });

  @override
  String toString() => 'AppException($runtimeType): $technicalDetail';
}

// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when a SQLite operation fails.
///
/// Named [AppDatabaseException] to avoid conflict with sqflite's own
/// [DatabaseException] class.
class AppDatabaseException extends AppException {
  const AppDatabaseException({
    required super.technicalDetail,
    super.userMessage = 'حدث خطأ في قاعدة البيانات. يرجى المحاولة مرة أخرى.',
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when form or business-rule validation fails.
///
/// [fieldErrors] maps field names to their Arabic validation messages.
class ValidationException extends AppException {
  /// Field-level errors. Key = field name, Value = Arabic error message.
  final Map<String, String>? fieldErrors;

  const ValidationException({
    required super.technicalDetail,
    super.userMessage = 'يوجد خطأ في البيانات المدخلة. يرجى المراجعة.',
    this.fieldErrors,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when a backup or restore operation fails.
class BackupException extends AppException {
  const BackupException({
    required super.technicalDetail,
    super.userMessage = 'فشلت عملية النسخ الاحتياطي. يرجى التحقق من المجلد المختار.',
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when an image copy, save, or delete operation fails.
class ImageStorageException extends AppException {
  const ImageStorageException({
    required super.technicalDetail,
    super.userMessage = 'فشل حفظ الصورة. يرجى المحاولة مرة أخرى.',
  });
}
