# Win Bucket

Native macOS Menüleisten-App (SwiftUI + AppKit), um berufliche Erfolge ("Wins") während des Jahres zu sammeln — als Nachweis für Gehaltsverhandlungen.

## Nutzung

```bash
swift run
```

Für den Login-Item-Schalter (braucht ein echtes `.app`-Bundle):

```bash
./Scripts/build_app.sh && open WinBucket.app
```

## Funktionen

- Menüleisten-Icon mit Popover: Dropzone für Dateien/Screenshots, Notizfeld, Link-Feld, Timeline aller Wins
- Hover-to-Open beim Draggen einer Datei aufs Icon
- Notiz mit lokaler Apple-KI (Foundation Models) von Stichpunkten zu Fließtext umformulieren, ohne erfundene Fakten
- Papierkorb mit Wiederherstellung (30 Tage Aufbewahrung)
- Export aller Wins als ZIP (Markdown + Anhänge)
- Wählbarer Speicherort, per Rechtsklick-Menü änderbar
- Rechtsklick-Menü: Ordner öffnen, Speicherort ändern, Login-Item, Beenden

Alle Daten bleiben lokal (kein Cloud-Sync).
