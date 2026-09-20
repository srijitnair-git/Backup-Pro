# Task 9: NAS Folder Browser & Honest Sync Status

**Status**: COMPLETED

## Context
User reported two more real bugs after using the app:
1. Folder pair destination was free-text entry — user has to type a NAS path by hand instead of picking a real folder, unlike the source (which already uses the device's native file picker).
2. The dashboard showed "Data Syncing..." and other active-looking state unconditionally, even when nothing was syncing.

## Fixes
- [x] Added `SMBClient.listFolders()` (uses `smb_connect`'s `listFiles`/`isDirectory()`) and `SMBClient.createFolder()`.
- [x] New `NasFolderBrowser` screen (`lib/ui/dashboard/nas_folder_browser.dart`): connects with the saved NAS credentials, lists real subfolders, lets you navigate in/out, create a new folder, and pick the current folder as the destination. Replaces the old destination text-entry dialog entirely.
- [x] `manual_folder_selection.dart`: adding a new folder pair now immediately opens the NAS browser to set the destination (a pair needs both halves, not one explicit + one silently defaulted), and the edit (pencil) action opens the same browser instead of a text field.
- [x] `live_transfer_dashboard.dart`: the header, progress bar, and both stat cards now reflect the real `sync_status` string instead of a hardcoded "Data Syncing..." label and a `progress`-only "Active/Idle" guess. Removed the fake, fully-static `fl_chart` line graph — it never represented real data at any state, active or idle, and reinforced the "looks busy when it's not" problem. Removed the now-unused `fl_chart` dependency.
- [x] Added a regression test asserting Idle state shows no "Syncing" text anywhere.

## Verification
- `flutter analyze --no-fatal-infos`: clean.
- `flutter test`: 7/7 pass (added 1).
- Verified live on `Pixel_6_API_34` emulator: home screen dashboard correctly shows "Idle" throughout with no fake data; NAS folder browser opens, shows the breadcrumb, and fails gracefully with a visible error (`Could not list folders: Can't connect to 192.168.1.50`) against a non-existent test NAS — no crash.
