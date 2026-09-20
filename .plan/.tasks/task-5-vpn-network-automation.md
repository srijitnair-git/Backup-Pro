# Task 5: Network Detection & VPN Automation

**Status**: COMPLETED

## Context
PRD's headline networking feature was entirely unimplemented as of the 2026-09-20 audit: no local-network detection, no VPN auto-trigger, and the existing `openVpnSettings()` stub was never even called from the sync flow.

User decision (2026-09-20 grill session): the app should detect which VPN apps are installed on the device and let the user pick a default in Settings, rather than hardcoding one VPN provider.

## Sub-tasks
- [x] Native Android MethodChannel (`MainActivity.kt`, channel `backup_pro/vpn`) to check which known VPN app packages are installed and to launch a package by name.
- [x] `VpnManager` (`lib/core/network/vpn_manager.dart`): LAN-reachability check via `Socket.connect` to the NAS IP/port with a short timeout; if unreachable, launches the user's preferred VPN app, then re-checks with 3 retries before giving up.
- [x] Settings screen: dropdown to pick preferred VPN app from installed candidates, persisted to `SharedPreferences` (`preferred_vpn_package`).
- [x] Wired `VpnManager.ensureOnNetwork()` into `background_service.dart`'s sync flow before `smbClient.connect()`. Aborts sync with `'Failed: Could not reach NAS (VPN required)'` if still unreachable.
- [x] Deleted the dead `openVpnSettings()` stub and the now-unused `url_launcher` dependency.
- [x] Added `<queries>` entries in `AndroidManifest.xml` for the 7 candidate VPN packages (required for package visibility on Android 11+, otherwise detection silently returns nothing) and added the missing `INTERNET`/`ACCESS_NETWORK_STATE` permissions (the app had neither — SMB and the new LAN check would have failed on a real device regardless of VPN logic).
- [x] Log and commit.

## Candidate VPN apps detected
WireGuard, Tailscale, OpenVPN Connect, NordVPN, ProtonVPN, ExpressVPN, Surfshark. Add more packages to the `candidatePackages` map in `MainActivity.kt` (and matching `<queries>` entry) if needed.
