# Phase 2: Core Engine, Background Services, UI, Branding & Release Pipeline

**Status**: COMPLETE (retroactive — this phase was never written down while the work happened, a RULES.md gap closed during a 2026-09-20 audit)

## Scope
Everything built after Phase 1's scaffold, up through the first working end-to-end release:
- SMB client, folder scanner, one-way sync engine (Task 2)
- WorkManager background scheduling, foreground service, home screen widgets (Task 3)
- Transfer resiliency: retry with exponential backoff (Task 4)
- Real VPN detection + auto-connect, replacing a dead stub (Task 5)
- Functional NAS/folder-configuration UI: test connection, source/destination pairs, per-folder sync status (Task 6)
- App branding (icon, splash, label) and version display + versioned CI releases (Task 7)
- Fixed real UI overlap bugs, the VPN-off-network background-isolate crash, and a missing `Workmanager().initialize()` call that broke every sync attempt (Task 8)
- Fixed CI itself: `flutter analyze`'s default `--fatal-infos` had failed every single run on this repo since the workflow was created

## Exit criteria (met)
- `flutter analyze` / `flutter test` clean and passing in CI
- A real device/emulator run confirmed no crashes through the VPN-check → SMB-connect path
- A downloadable, versioned APK is published automatically via GitHub Releases on every push to `main`

## Not in this phase (still open, tracked as `proposed` in ArcNode)
Diagnostic logging, file size/type filters, SMS & call log extraction, and the open-source license file — all named in the original PRD, none built yet.
