# Reader iOS - Agent Instructions

This project uses **bd** (beads) for issue tracking and **gt** (Gas Town) for agent coordination.

---

## BEFORE YOU START (READ THIS FIRST)

**Crew and Polecats: ALWAYS pull before doing any work.**

```bash
git pull origin main
```

Polecats merge work while you're offline. If you skip this step, you'll work on stale code and potentially duplicate or conflict with completed work.

---

## Project Overview

Reader iOS is a native SwiftUI companion app for the Reader book tracking service. Users log in and browse their book shelves on iPhone.

### Tech Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI |
| Language | Swift 5.9+ |
| Minimum iOS | 17.0 |
| Networking | URLSession (async/await) |
| Storage | Keychain (credentials only) |
| Dependencies | None (pure Apple frameworks) |

### Key Files

- **Services/APIClient.swift** - Network layer + all data models
- **Services/AuthManager.swift** - Authentication state (@Observable)
- **Services/KeychainHelper.swift** - Secure credential storage
- **Views/LoginView.swift** - Login screen
- **Views/ShelvesListView.swift** - Shelves list
- **Views/ShelfDetailView.swift** - Books in shelf
- **Views/BookDetailView.swift** - Single book details

### Backend API

Communicates with Reader Rails backend at `http://localhost:3000` (dev).

```
POST /api/v1/sessions        # Login → user_id + api_key
GET  /api/v1/shelves         # List shelves
GET  /api/v1/shelves/:id     # Shelf with books (in progress)
GET  /api/v1/books/:id       # Book details (in progress)
```

*All GET requests require `?api_key=...&user_id=...` query params.*

### Building

Open `booktracker-ios.xcodeproj` in Xcode and build for simulator or device.

### Documentation

- `doc/PRD.md` - Product requirements
- `doc/SDD.md` - Software design
- `doc/reader_platform_roadmap.md` - Cross-platform roadmap
- `doc/screen_api_mapping.md` - Screen to API mapping

---

## Quick Reference

```bash
# FIRST: Always sync before starting
git pull origin main

# Find and claim work
bd ready              # Find available work
bd show <id>          # View issue details
gt hook               # Check your hooked work (polecats)

# Complete work
bd close <id>         # Mark work done
bd sync               # Sync beads
git push origin HEAD  # Push changes
gt done               # Signal done (polecats only)
```

---

## Polecat Workflow (CRITICAL)

If you are a **polecat** (worker agent), follow this EXACT workflow:

### 1. On Startup - Sync and Check Hook

```bash
# FIRST: Pull latest from main (polecats may have merged while you were idle)
git pull origin main

# THEN: Check your assigned work
gt hook
```

This shows the bead assigned to you. Read it carefully - this is your task.

### 2. Do the Work

- Implement what the bead describes
- Make atomic commits as you go
- Run tests if applicable

### 3. On Completion - MANDATORY STEPS

You MUST complete ALL of these steps. Work is NOT done until all succeed:

```bash
# 1. Stage and commit your changes
git add -A
git commit -m "Description of what you did"

# 2. Close your bead (USE THE ACTUAL BEAD ID from gt hook)
bd close <bead-id> --reason="Implemented feature"

# 3. Sync beads
bd sync

# 4. Push to remote - MANDATORY
git push origin HEAD

# 5. Verify push succeeded
git status  # Must show "up to date with origin" or "ahead" is OK if remote updated

# 6. Signal done to Gas Town
gt done
```

### CRITICAL RULES

- **ALWAYS close your bead** - Use `bd close <id>` with the bead ID from `gt hook`
- **ALWAYS push** - Work is NOT complete until `git push` succeeds
- **ALWAYS run `gt done`** - This signals Gas Town you're finished
- **NEVER stop before pushing** - That leaves work stranded locally
- **NEVER say "ready to push when you are"** - YOU must push

### If Push Fails

```bash
git pull --rebase origin main
# Resolve any conflicts
git push origin HEAD
```

---

## Landing the Plane (Session Completion)

**When ending a work session**, complete ALL steps:

1. **Commit all changes** - `git add -A && git commit -m "..."`
2. **Close your bead** - `bd close <bead-id>`
3. **Sync beads** - `bd sync`
4. **Push to remote** - `git push origin HEAD`
5. **Signal done** - `gt done`
6. **Verify** - `git status` shows clean and pushed

---

## For Crew (Human-Managed Workers)

Crew members follow the same workflow but without `gt done` (you're managed by a human, not Gas Town).

### CRITICAL: Pull Before Starting Work

Crew worktrees persist across sessions. Polecats may have merged work to main while you were offline. **ALWAYS pull before starting any work:**

```bash
# EVERY session start - MANDATORY
git pull origin main
```

If you skip this, you'll be working on stale code and may miss features that polecats already implemented.

### On Completion

```bash
git add -A && git commit -m "..."
bd close <bead-id>
bd sync
git push origin main
```
