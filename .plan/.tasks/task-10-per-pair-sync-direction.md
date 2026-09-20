# Task 10: Per-Pair Sync Direction

**Status**: COMPLETED

## Context
Research into FolderSync Pro (the app this project replaces) found it supports three sync directions per folder pair: to-destination-only, from-destination-only, and two-way. Backup Pro only ever does one-way-to-NAS. User picked this as the one FolderSync Pro capability worth adding now; explicitly declined multi-cloud backends, app lock, Tasker integration, file filters, per-pair schedules, and versioned backups as out of scope for now.

## Sub-tasks
- [x] Extract a shared `FolderPair` model (`lib/core/models/folder_pair.dart`) with a `SyncDirection` enum (`toNas`, `fromNas`, `twoWay`), used by both the UI and the background sync engine instead of raw JSON maps.
- [x] `SMBClient`: added `listFilesRecursive` (walks NAS subfolders, returns relative path + mtime for files) and `downloadFile`.
- [x] `background_service.dart`: split into `_syncToNas`/`_syncFromNas`/`_syncTwoWay` helpers, dispatched per pair via `switch (pair.direction)`.
- [x] `manual_folder_selection.dart`: `SegmentedButton<SyncDirection>` on each folder card (To / From / Two-Way).
- [x] Log and commit.

## Known simplification
Two-way conflict handling is skip-only (no overwrite/rename policy choice) — matches FolderSync Pro's own default behavior, and per-pair conflict *policy* selection was one of the explicitly declined items (file filters/schedules bucket). Upgrade path: add a policy choice later if needed.

## Verification
- `flutter analyze --no-fatal-infos`: clean.
- `flutter test`: 9/9 pass (added `FolderPair` JSON round-trip + legacy-data-defaults-to-toNas tests).
- Verified live on the emulator: seeded a `twoWay` folder pair via SharedPreferences, confirmed the segmented control shows the correct pre-selected direction and switching segments (`To`/`From`/`Two-Way`) updates the selection correctly.
