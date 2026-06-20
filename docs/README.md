# Dear Diary — Product Requirements Document

> **Version:** 1.0.0  
> **Status:** Active Development  
> **Platform:** Flutter (iOS + Android)  
> **Architecture:** Clean Architecture + Riverpod  

---

## 📁 Document Index

This PRD is structured as a set of focused markdown files. Read them in order for onboarding, or jump to the relevant section during implementation.

| File | Purpose |
|------|---------|
| [`docs/01-vision.md`](docs/01-vision.md) | Product vision, goals, non-goals |
| [`docs/02-features.md`](docs/02-features.md) | MVP feature specifications |
| [`docs/03-architecture.md`](docs/03-architecture.md) | Technical architecture & folder structure |
| [`docs/04-data-models.md`](docs/04-data-models.md) | Database schema, models, storage design |
| [`docs/05-security.md`](docs/05-security.md) | Security architecture & encryption strategy |
| [`docs/06-audio-system.md`](docs/06-audio-system.md) | Audio recording & playback system |
| [`docs/07-ui-ux.md`](docs/07-ui-ux.md) | UI/UX principles, responsive design |
| [`docs/08-search.md`](docs/08-search.md) | Search system design |
| [`docs/09-performance.md`](docs/09-performance.md) | Performance guidelines |
| [`docs/10-roadmap.md`](docs/10-roadmap.md) | Future roadmap |
| [`edge-cases/00-overview.md`](edge-cases/00-overview.md) | Edge case handling overview |
| [`edge-cases/01-storage.md`](edge-cases/01-storage.md) | Storage edge cases |
| [`edge-cases/02-audio.md`](edge-cases/02-audio.md) | Audio edge cases |
| [`edge-cases/03-auth-security.md`](edge-cases/03-auth-security.md) | Auth & security edge cases |
| [`edge-cases/04-permissions.md`](edge-cases/04-permissions.md) | Permission edge cases |
| [`edge-cases/05-data-integrity.md`](edge-cases/05-data-integrity.md) | Data integrity & corruption edge cases |
| [`edge-cases/06-platform-os.md`](edge-cases/06-platform-os.md) | Platform & OS-specific edge cases |
| [`edge-cases/07-ui-state.md`](edge-cases/07-ui-state.md) | UI state & navigation edge cases |

---

## 🚀 Quick Start for Developers

1. Read [`docs/01-vision.md`](docs/01-vision.md) to internalize the philosophy.
2. Read [`docs/03-architecture.md`](docs/03-architecture.md) for folder structure and layering rules.
3. Read [`docs/05-security.md`](docs/05-security.md) — security is non-negotiable; understand it before writing any data code.
4. Skim [`edge-cases/00-overview.md`](edge-cases/00-overview.md) to understand the failure modes the app must handle.
5. Refer to individual feature docs and edge case files as you build each module.

---

## 🧭 Philosophy (TL;DR)

> The app must feel **safe**, **fast**, **private**, and **emotionally lightweight**.  
> Every decision — technical and product — should support that.

- No accounts. No cloud. No analytics. No trackers.
- Encryption at rest. Biometric at the door.
- Open → Write/Record → Save → Exit.
