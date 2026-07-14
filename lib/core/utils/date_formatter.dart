import 'package:intl/intl.dart';

/// Centralized date formatting utilities.
///
/// All date display strings in the application must come from here.
/// Never use [DateFormat] directly inside widgets or repositories.
class DateFormatter {
  DateFormatter._();

  static final _displayFormat = DateFormat('yyyy/MM/dd');
  static final _displayWithTimeFormat = DateFormat('yyyy/MM/dd HH:mm');
  static final _backupTimestampFormat = DateFormat('yyyy_MM_dd_HH_mm');
  static final _logTimestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final _monthYearFormat = DateFormat('MMMM yyyy', 'ar');

  // ── Display helpers ───────────────────────────────────────────────────────

  /// Returns `yyyy/MM/dd` — used in cards and tables.
  static String toDisplay(DateTime date) => _displayFormat.format(date);

  /// Returns `yyyy/MM/dd HH:mm` — used in audit logs and timestamps.
  static String toDisplayWithTime(DateTime date) =>
      _displayWithTimeFormat.format(date);

  /// Returns `MMMM yyyy` in Arabic — used in monthly report headers.
  static String toMonthYear(DateTime date) => _monthYearFormat.format(date);

  // ── Storage helpers ───────────────────────────────────────────────────────

  /// Returns ISO-8601 string for SQLite storage.
  static String toIso(DateTime date) => date.toIso8601String();

  /// Parses an ISO-8601 string from the database.
  static DateTime fromIso(String iso) => DateTime.parse(iso);

  // ── Backup helpers ────────────────────────────────────────────────────────

  /// Returns `yyyy_MM_dd_HH_mm` — used as the backup folder suffix.
  ///
  /// Example: `jumaa_backup_2026_07_14_15_30`
  static String toBackupTimestamp(DateTime date) =>
      _backupTimestampFormat.format(date);

  /// Returns `yyyy-MM-dd HH:mm:ss` — used in log file lines.
  static String toLogTimestamp(DateTime date) =>
      _logTimestampFormat.format(date);

  // ── Parsing helpers ───────────────────────────────────────────────────────

  /// Safely parses a nullable ISO string. Returns null if [iso] is null.
  static DateTime? fromIsoNullable(String? iso) =>
      iso == null ? null : DateTime.tryParse(iso);

  /// Returns today at midnight.
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns the first day of the current month at midnight.
  static DateTime startOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, 1);
  }

  /// Returns the last moment of the current month.
  static DateTime endOfMonth([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month + 1, 1)
        .subtract(const Duration(milliseconds: 1));
  }
}
