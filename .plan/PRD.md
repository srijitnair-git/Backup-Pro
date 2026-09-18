# Backup Pro - Product Requirements Document (PRD)

## 1. Vision & Goals
Backup Pro is a free, open-source Android (and future iOS) application designed to completely replace "FolderSync" for a personal group of 3-4 users. It provides robust, resilient, and fully automated one-way archiving of folders to a personal NAS over an SMB/CIFS connection.

## 2. Core Features
- **One-Way Archive Sync**: Copies new and modified files to the NAS. Files deleted on the device remain safe on the NAS.
- **Global Storage Scanner**: Leverages `MANAGE_EXTERNAL_STORAGE` to access and backup any folder on the device.
- **Network & VPN Automation**: 
  - Detects if the device is on the local network. 
  - If remote, it automatically triggers a third-party VPN app (via Intents) to secure the connection before syncing.
- **Background Autonomy**: Scheduled via Android WorkManager based on constraints (e.g., Wi-Fi, Charging). It spawns a Persistent Foreground Service during active transfers to prevent the OS from killing the process.
- **Transfer Resiliency**: Handles network drops, broken connections, and resumes partial copies using an exponential backoff strategy. File filters apply size and type constraints.

## 3. UI/UX & Design
- **Premium Design System**: Enforces a strict, consistent color palette, typography, Light/Dark modes, and smooth button animations.
- **Live Transfer Dashboard**: Visually rich interface showing real-time transfer speeds, loading screens, and progress bars.
- **System & Lockscreen Alerts**: OS-level notifications provide unmissable updates on backup states.
- **Home Screen Widget**: 3 widget sizes showing the latest backup status and a manual "Backup Now" trigger.

## 4. DevOps, Distribution & Licensing
- **CI/CD Pipeline**: Automated GitHub Actions pipeline to build the `.aab` and push to the Google Play Store.
- **License**: Free open-source license (e.g., MIT).
