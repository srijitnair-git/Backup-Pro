# Task 6: UI Functionality Fixes

**Status**: COMPLETED

## Context
User flagged mid-audit: UI is not functional for real use.
1. No way to test NAS credentials/connection before saving or syncing — you find out it's broken only when a background sync silently fails.
2. Folder selection only picks a source path; there's no explicit destination path per folder (remote path is auto-derived and invisible to the user).
3. No per-folder sync status — the folder list doesn't show whether each folder is synced, pending, or never synced.

## Sub-tasks
- [x] `settings_screen.dart`: "Test Connection" button runs `SMBClient.connect()`/`disconnect()` against entered credentials and shows success/failure inline.
- [x] `manual_folder_selection.dart`: folder pairs now stored as `{local, remote}` (JSON in SharedPreferences key `backup_folder_pairs`, replacing the flat `selected_backup_folders` list). Old installs auto-migrate on first load.
- [x] `manual_folder_selection.dart`: each folder shows last-synced time (or "Never synced") read from `last_sync_<path>`, with a cloud-done/cloud-off status icon, and an edit button to change the destination path.
- [x] `background_service.dart`: reads the new `{local, remote}` structure instead of deriving the remote path from the folder name.
- [x] Log and commit.
