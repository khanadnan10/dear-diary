# Dear Diary — Antigravity Index

This file lists every PRD document in read order. Load all files before starting any task.

---

## Core PRD

1. `docs/01-vision.md` — Product goals, non-goals, success criteria
2. `docs/02-features.md` — MVP feature specs with acceptance criteria
3. `docs/03-architecture.md` — Layering rules, folder structure, tech stack
4. `docs/04-data-models.md` — Isar schema, encryption key storage, audio file layout
5. `docs/05-security.md` — Threat model, biometric flow, AES-256-GCM, screenshot prevention
6. `docs/06-audio-system.md` — RecordingService, PlaybackService, audio focus handling
7. `docs/07-ui-ux.md` — Design language, screen map, responsive breakpoints, accessibility
8. `docs/08-search.md` — Local search strategy, result format
9. `docs/09-performance.md` — Startup, rendering, audio, battery targets
10. `docs/10-roadmap.md` — Post-MVP features, permanent exclusions

---

## Edge Cases

11. `edge-cases/00-overview.md` — Handling philosophy, AppException hierarchy
12. `edge-cases/01-storage.md` — Disk full, DB corruption, migration, orphaned files, interrupted saves
13. `edge-cases/02-audio.md` — Call interruptions, focus loss, permission revoke, zero-byte files, codec errors
14. `edge-cases/03-auth-security.md` — Biometric failures, key loss, session timeout, app switcher leak
15. `edge-cases/04-permissions.md` — Denied mic, Android storage, all-permissions-denied state
16. `edge-cases/05-data-integrity.md` — Decryption failure, empty entries, UUID collision, orphaned audio, large text
17. `edge-cases/06-platform-os.md` — OEM battery killers, Keystore wipe, schema migration, emulator bypass
18. `edge-cases/07-ui-state.md` — Back nav during recording, rapid saves, scroll state, keyboard overlap, orientation changes
