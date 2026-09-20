# Task 3: Background Services

**Status**: PARTIALLY COMPLETE

## Context
Following the core logic implementation, we need to setup background autonomy for folder synchronization.

## Sub-tasks
- [x] Implement Android WorkManager integration for scheduled background operations.
- [x] Implement Foreground Service + 3 home screen widget sizes for sync status/manual trigger.
- [ ] Implement VPN Intent toggling. (`openVpnSettings()` exists but only opens system VPN settings — not real network detection or auto-trigger; superseded by Task 5)
- [ ] Write rigorous unit tests.
- [ ] Log and commit.

## Note
This file was out of sync with actual commits (marked NOT STARTED while 5 commits landed implementing most of it). Reconciled 2026-09-20.
