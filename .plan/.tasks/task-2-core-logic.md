# Task 2: Core Logic - SMB Client & Folder Scanner

**Status**: COMPLETED

## Context
Before we can build the UI, we need the core engine to be functional. This task focuses on establishing the low-level protocols: acquiring the correct native Android permissions to scan the filesystem (`MANAGE_EXTERNAL_STORAGE`) and implementing the SMB client to connect and transfer files to the NAS.

## Sub-tasks
- [ ] Add `smb_client` (or similar minimal standard dependency) to `pubspec.yaml`.
- [ ] Implement `SMBClient` class inside `lib/core/network/` for connecting and uploading.
- [ ] Update `AndroidManifest.xml` with `MANAGE_EXTERNAL_STORAGE` and `READ_EXTERNAL_STORAGE`.
- [ ] Implement `FolderScanner` inside `lib/core/engine/` using standard dart `Directory` logic.
- [ ] Write a minimal `assert`-based test in `main.dart` or a basic unit test to verify the connection logic.
- [ ] Log and commit.
