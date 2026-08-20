# Logging und Diagnose

## Ziel

Einheitliches, reproduzierbares Logging fuer Support und Fehleranalyse.

## Implementierung

- Logger: [../lib/services/app_logger.dart](../lib/services/app_logger.dart)
- Hooking in App-Start: [../lib/main.dart](../lib/main.dart)
- Controller-Logs: [../lib/controllers/campaign_controller.dart](../lib/controllers/campaign_controller.dart)

## Log-Level

- `debug`
- `info`
- `warning`
- `error`

## Format

`[timestamp] [LEVEL] [source] message | error: ... | stack: ...`

## Speicherort

- Laufzeit: Debug-Konsole (`debugPrint`)
- Lokal persistent: SharedPreferences Key `fc26_app_logs`
- Ringpuffer: max. 400 Eintraege

## Empfehlung fuer neue Features

1. Fuer wichtige User-Aktionen `info` loggen.
2. Fuer recoverable Probleme `warning` loggen.
3. Fuer Ausnahmen `error` mit StackTrace loggen.
4. Keine verstreuten `print`-Statements verwenden.
