import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Application-wide logger.
///
/// Writes structured log lines to a daily rotating file under:
///   `<appSupportDir>/logs/jumaa_YYYY-MM-DD.log`
///
/// Also prints to the debug console in debug builds.
///
/// Call [AppLogger.instance.initialize()] in `main()` before [runApp].
///
/// Usage:
/// ```dart
/// AppLogger.instance.info('Customer loaded', tag: 'CustomerRepository');
/// AppLogger.instance.error('DB failed', tag: 'DatabaseService', exception: e);
/// ```
class AppLogger {
  AppLogger._();

  /// Singleton instance.
  static final AppLogger instance = AppLogger._();

  File? _logFile;
  bool _initialized = false;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Must be called once during app startup (before [runApp]).
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final logsDir = Directory('${dir.path}/logs');
      if (!logsDir.existsSync()) {
        logsDir.createSync(recursive: true);
      }
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logsDir.path}/jumaa_$dateStr.log');
      _initialized = true;
      info('Logger initialized. Log file: ${_logFile!.path}', tag: 'AppLogger');
    } catch (e) {
      // Logger must never crash the app. Degrade gracefully to console-only.
      debugPrint('[AppLogger] Failed to initialize file logger: $e');
    }
  }

  /// Logs an informational message.
  void info(String message, {String? tag}) {
    _write('INFO', tag, message);
  }

  /// Logs a warning message.
  void warning(String message, {String? tag}) {
    _write('WARN', tag, message);
  }

  /// Logs an error. Pass [exception] for the technical detail.
  void error(String message, {String? tag, Object? exception}) {
    final detail = exception != null ? '$message | Exception: $exception' : message;
    _write('ERROR', tag, detail);
  }

  /// Logs a critical operation (backup, restore, delete, etc.).
  void audit(String message, {String? tag}) {
    _write('AUDIT', tag, message);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _write(String level, String? tag, String message) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final tagPart = tag != null ? '[$tag]' : '';
    final line = '[$timestamp][$level]$tagPart $message';

    // Always print to debug console in debug mode.
    if (kDebugMode) {
      debugPrint(line);
    }

    // Write to file (non-blocking, best-effort).
    _appendToFile('$line\n');
  }

  void _appendToFile(String line) {
    try {
      _logFile?.writeAsStringSync(line, mode: FileMode.append, flush: false);
    } catch (_) {
      // File write errors must never propagate to the UI.
    }
  }
}
