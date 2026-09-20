# Task 4: Transfer Resiliency

**Status**: COMPLETED

## Context
PRD requires: "Handles network drops, broken connections, and resumes partial copies using an exponential backoff strategy." Audit on 2026-09-20 found `smb_client.dart` had zero retry logic — any drop mid-upload aborted the entire folder's sync loop.

## Sub-tasks
- [x] Add exponential-backoff retry wrapper around `connect()` and `uploadFile()`. (`lib/core/network/retry.dart`, `withRetry`)
- [x] Per-file failure should not abort the whole folder loop — skip and continue, log the failed file.
- [x] Only mark a folder's `lastSyncTime` complete if all files in that pass succeeded (so failed files get retried next run).
- [x] Log and commit.

## Known simplification
File-level resume (retry the whole file), not byte-level resume (resuming mid-upload of a single large file). `smb_connect` doesn't expose a clean append/seek write API for this. Marked with a `ponytail:` comment at the ceiling in `background_service.dart`.
