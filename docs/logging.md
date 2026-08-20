# Logging and Diagnostics

## Goal

Unified, reproducible logging for support and troubleshooting.

## Implementation

- Logger: [../lib/services/app_logger.dart](../lib/services/app_logger.dart)
- Hooked in at app start: [../lib/main.dart](../lib/main.dart)
- Controller logs: [../lib/controllers/campaign_controller.dart](../lib/controllers/campaign_controller.dart)

## Log Levels

- `debug`
- `info`
- `warning`
- `error`

## Format

`[timestamp] [LEVEL] [source] message | error: ... | stack: ...`

## Storage

- Runtime: debug console (`debugPrint`)
- Local persistence: SharedPreferences key `fc26_app_logs`
- Ring buffer: max. 400 entries

## Recommendation for New Features

1. Log `info` for important user actions.
2. Log `warning` for recoverable problems.
3. Log `error` with a stack trace for exceptions.
4. Do not use scattered `print` statements.
