import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();
  static const _storageKey = 'fc26_app_logs';
  static const _maxEntries = 400;

  Future<void> debug(String source, String message) {
    return _log(level: LogLevel.debug, source: source, message: message);
  }

  Future<void> info(String source, String message) {
    return _log(level: LogLevel.info, source: source, message: message);
  }

  Future<void> warning(String source, String message) {
    return _log(level: LogLevel.warning, source: source, message: message);
  }

  Future<void> error(
    String source,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    return _log(
      level: LogLevel.error,
      source: source,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<List<String>> recentLogs({int limit = 200}) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(_storageKey) ?? const <String>[];
    if (limit <= 0 || all.length <= limit) {
      return all;
    }
    return all.sublist(all.length - limit);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _log({
    required LogLevel level,
    required String source,
    required String message,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final sb = StringBuffer()
      ..write('[$timestamp] [${level.name.toUpperCase()}] [$source] $message');

    if (error != null) {
      sb.write(' | error: $error');
    }
    if (stackTrace != null) {
      sb.write(' | stack: ${_oneLine(stackTrace.toString())}');
    }

    final entry = sb.toString();
    debugPrint(entry);

    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_storageKey) ?? <String>[];
      logs.add(entry);
      if (logs.length > _maxEntries) {
        logs.removeRange(0, logs.length - _maxEntries);
      }
      await prefs.setStringList(_storageKey, logs);
    } catch (_) {
      // Avoid crashing app because logger persistence failed.
    }
  }

  String _oneLine(String value) {
    return value.replaceAll('\n', ' | ').replaceAll('\r', '');
  }
}
