# Win Bucket

Native macOS menu bar app (SwiftUI + AppKit) for collecting professional wins throughout the year — as evidence for salary negotiations.

## Usage

```bash
swift run
```

For the login-item toggle (needs a real `.app` bundle):

```bash
./Scripts/build_app.sh && open WinBucket.app
```

## Features

- Menu bar icon with popover: drop zone for files/screenshots, note field, link field, timeline of all wins
- Hover-to-open when dragging a file onto the icon
- Rewrite a note from bullet points into full sentences with local Apple AI (Foundation Models), without inventing facts
- Trash with restore (30-day retention)
- Export all wins as a ZIP (Markdown + attachments)
- Choosable storage location, changeable via right-click menu
- Right-click menu: open folder, change location, login item, quit

All data stays local (no cloud sync).
