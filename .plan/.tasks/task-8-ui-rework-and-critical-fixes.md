# Task 8: UI Rework, VPN Background Fix, and Workmanager Init Bug

**Status**: COMPLETED

## Context
User reported three issues after using the app on a real device/emulator:
1. UI is cluttered/overlapping.
2. Can't find the per-folder source/destination setting (it exists, from Task 6).
3. VPN doesn't try to connect when off the local network.

Verified all three live on a Pixel 6 API 34 emulator (`flutter emulators --launch Pixel_6_API_34`) rather than guessing from code.

## Findings & Fixes
- [x] **Real overlap bug**: `manual_folder_selection.dart`'s folder card used `ListTile(isThreeLine: true)` with a 3-line subtitle Column (From/To/status) + title = 4 lines of content squeezed into a layout budgeted for 3. This clipped/overlapped the destination and status text — which is *why* the per-folder destination setting looked missing (issue 2 was actually issue 1's symptom). Replaced with a custom `Container`/`Column` card with no fixed-line budget; destination is now clearly visible and editable.
- [x] **Real overlap bug**: `home_screen.dart` used a fixed `bottomNavigationBar` (the "Sync Now" button) over a `SingleChildScrollView` body. Confirmed via emulator screenshots that the last tile ("System Status") was genuinely painted behind the button, not just tightly spaced (scrolling didn't reveal more — content already fit, meaning Scaffold wasn't reserving the space visually implied). Removed `bottomNavigationBar` entirely; "Sync Now" is now the last item in the natural scroll flow, which structurally cannot overlap anything.
- [x] **Real bug**: `live_transfer_dashboard.dart`'s two stat cards used a hardcoded `width: (MediaQuery.width - 72) / 2` with `mainAxisAlignment.spaceBetween` and no gap — cards sat flush against each other with zero spacing. Replaced with `Expanded` + explicit `SizedBox(width: 12)` gap.
- [x] Restyled `settings_screen.dart` (previously plain default Material fields, visually inconsistent with the rest of the app) into grouped premium-styled sections ("NAS Credentials", "VPN Automation") matching the dark card look used elsewhere.
- [x] **Root cause of VPN not connecting off-network**: confirmed via a research subagent reading the `workmanager_android` plugin source (`BackgroundWorker.kt`) that Workmanager's headless background isolate creates its own `FlutterEngine` which auto-registers only *real* pub-declared plugins (via `GeneratedPluginRegistrant`) — never `MainActivity`'s ad-hoc `configureFlutterEngine` channel setup. So `MethodChannel('backup_pro/vpn').invokeMethod('launchPackage', ...)`, called from inside the Workmanager `callbackDispatcher`, always threw `MissingPluginException`, silently killing the background sync task before any VPN attempt. Fixed by launching the VPN app via `url_launcher`'s `android-app://<package>` scheme instead (a real registered plugin, works in both the UI and headless engines). Kept the native channel only for `getInstalledVpnApps` (Settings screen, foreground-only). Verified via logcat: the background task now runs to completion (`NAS unreachable and VPN could not establish connectivity.` / Worker RETRY) instead of crashing.
- [x] **Bonus bug found while testing**: `BackgroundService().initialize()` (which calls `Workmanager().initialize(...)`) was never called anywhere in the app — `main.dart` went straight to `runApp()`. Every tap of "Sync Now" threw `PlatformException: You have not properly initialized the Flutter WorkManager Package.` Fixed by calling it in `main()` before `runApp()`.

## Verification
- `flutter analyze --no-fatal-infos`: clean (same 19 pre-existing info-level lints, no new warnings/errors).
- `flutter test`: 6/6 pass.
- Manually verified on `Pixel_6_API_34` emulator via `adb`: home screen spacing (screenshots, scroll test), folder card with seeded `backup_folder_pairs` data (both a "Never synced" and a "Last synced" entry), Settings screen restyle, and a live "Sync Now" trigger confirming no crash through the VPN-check → SMB-connect-failure path.
