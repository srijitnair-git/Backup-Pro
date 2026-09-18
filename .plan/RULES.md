# Backup Pro - Strict Project Rules

**CRITICAL: THESE RULES MUST BE FOLLOWED ON EVERY TASK AND EVERY INTERACTION.**

## 1. Planning & Tracking
- **No rogue coding**: Every feature must first be documented in a `.plan/.tasks/` markdown file before implementation.
- **Phases**: Major milestones must be outlined in `.plan/.phases/`.
- **ArcNode Truth**: ArcNode (`.arcnode/map.json`) is the ultimate source of truth for the project's meaning and architecture. Update it whenever the system's shape changes.

## 2. Universal Logging
- **The Log**: EVERY decision, testing outcome, user feedback, and code change must be logged in the current day's log file inside `.plan/logs/`.
- **ArcNode Testing**: Every time `arcnode audit` is run, its success, speed, and any bugs must be appended to `.arcnode/updates.log`.

## 3. Codebase Standards (Ponytail & Ponyman)
- **Minimalism**: Follow the `ponytail` ladder. Do not add unrequested abstractions, factories, or speculative code. Re-use existing widgets, components, and standard libraries.
- **Clean Folder Structure**: Keep the app strictly organized. No loose, unnecessary, or dead files.
- **Constant Auditing**: Run `/audit-codebase-ponyman` and `/grill-me` at the conclusion of *every* stage.

## 4. Version Control
- Commit logical chunks to GitHub. Do not leave the repository with uncommitted, working-state code for long periods.
