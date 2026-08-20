# Troubleshooting

## 1) `SDK root directory not found: ../.puro/.../flutter_web_sdk`

Symptom:

- `flutter run -d chrome` fails with a `.puro`-related SDK path.

Cause:

- The current terminal session is invoking the wrong `flutter` binary.

Solution:

1. Close all VS Code terminals.
2. Open a new terminal.
3. Start explicitly using your Flutter SDK path, e.g.:
   - `<flutter-sdk>\bin\flutter.bat clean`
   - `<flutter-sdk>\bin\flutter.bat pub get`
   - `<flutter-sdk>\bin\flutter.bat run -d chrome`
4. Optional: use the VS Code task `Flutter: Verify + Run Chrome (flutter-clean)`.

## 2) Unexplained compiler errors on old file states

Symptom:

- Errors don't match the current file content.

Solution:

1. `flutter clean`
2. `flutter pub get`
3. Restart the IDE
4. Re-run `analyze`/`run` with your explicit Flutter SDK

## 3) No saved campaign present

Symptom:

- "Continue" button shown without a campaign.

Solution:

- Start a new campaign; state is then persisted locally.

## 4) Preparing a bug report

Always include with a bug report:

1. Exact command
2. Komplette Fehlermeldung
3. Relevante Logs (source + timestamp)
4. Aktiver SDK-Pfad aus [../.vscode/settings.json](../.vscode/settings.json)
