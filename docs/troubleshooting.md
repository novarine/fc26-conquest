# Troubleshooting

## 1) `SDK root directory not found: ../.puro/.../flutter_web_sdk`

Symptom:

- `flutter run -d chrome` bricht mit `.puro`-bezogenem SDK-Pfad ab.

Ursache:

- In der aktuellen Terminal-Session wird ein falsches `flutter` Binary aufgerufen.

Loesung:

1. Alle VS Code-Terminals schliessen.
2. Neues Terminal oeffnen.
3. Explizit starten:
   - `C:\Users\marti\flutter-clean\bin\flutter.bat clean`
   - `C:\Users\marti\flutter-clean\bin\flutter.bat pub get`
   - `C:\Users\marti\flutter-clean\bin\flutter.bat run -d chrome`
4. Optional: VS Code Task `Flutter: Verify + Run Chrome (flutter-clean)` verwenden.

## 2) Unerklaerliche Compilerfehler in alten Dateistaenden

Symptom:

- Fehler passen nicht zum aktuellen Dateicontent.

Loesung:

1. `flutter clean`
2. `flutter pub get`
3. IDE neu starten
4. Erneut `analyze`/`run` mit flutter-clean

## 3) Keine gespeicherte Kampagne vorhanden

Symptom:

- Weiterfuehren-Button ohne Kampagne.

Loesung:

- Neue Kampagne starten, danach wird Zustand lokal persistiert.

## 4) Fehleranalyse vorbereiten

Bei Bugreport immer mitschicken:

1. Exakter Befehl
2. Komplette Fehlermeldung
3. Relevante Logs (source + timestamp)
4. Aktiver SDK-Pfad aus [../.vscode/settings.json](../.vscode/settings.json)
