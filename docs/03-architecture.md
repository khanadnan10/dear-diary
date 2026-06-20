# 03 — Architecture Overview

## Layering Model

```
┌──────────────────────────────────────────────┐
│              Presentation Layer               │
│         (Flutter Widgets + Pages)             │
├──────────────────────────────────────────────┤
│           Riverpod State Layer                │
│     (Providers, Notifiers, AsyncNotifiers)    │
├──────────────────────────────────────────────┤
│               Domain Layer                    │
│       (Use Cases, Entities, Repositories)     │
├──────────────────────────────────────────────┤
│                Data Layer                     │
│   (Repository Impls, Data Sources, Mappers)   │
├────────────┬───────────┬──────────────────────┤
│  Isar DB   │  Secure   │  File Storage /      │
│ (metadata) │  Storage  │  Device Services     │
└────────────┴───────────┴──────────────────────┘
```

### Rules
- Presentation → Domain only (never imports data layer directly)
- Domain has zero Flutter dependencies
- Data layer implements domain interfaces
- Riverpod providers live at the boundary of presentation and domain

---

## Folder Structure

```
lib/
├── app/
│   ├── app.dart                  # MaterialApp root
│   └── app_theme.dart            # ThemeData definitions
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── errors/
│   │   ├── app_exception.dart    # Base exception class
│   │   └── failure.dart          # Domain-level failures
│   ├── utils/
│   │   ├── logger.dart
│   │   └── date_formatter.dart
│   └── extensions/
│       └── string_extensions.dart
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_service.dart
│   │   ├── domain/
│   │   │   └── auth_repository.dart
│   │   └── presentation/
│   │       └── lock_screen.dart
│   │
│   ├── diary/
│   │   ├── data/
│   │   │   ├── diary_repository_impl.dart
│   │   │   ├── diary_local_datasource.dart
│   │   │   └── models/diary_entry_isar.dart
│   │   ├── domain/
│   │   │   ├── entities/diary_entry.dart
│   │   │   ├── repositories/diary_repository.dart
│   │   │   └── usecases/
│   │   │       ├── create_entry.dart
│   │   │       ├── update_entry.dart
│   │   │       ├── delete_entry.dart
│   │   │       └── get_entries.dart
│   │   └── presentation/
│   │       ├── diary_list_page.dart
│   │       ├── diary_entry_page.dart
│   │       └── providers/diary_provider.dart
│   │
│   ├── audio/
│   │   ├── data/
│   │   │   ├── recording_service.dart
│   │   │   └── playback_service.dart
│   │   ├── domain/
│   │   │   └── audio_repository.dart
│   │   └── presentation/
│   │       ├── recorder_widget.dart
│   │       └── player_widget.dart
│   │
│   ├── search/
│   │   ├── domain/
│   │   │   └── search_usecase.dart
│   │   └── presentation/
│   │       └── search_page.dart
│   │
│   └── settings/
│       ├── domain/
│       │   └── settings_repository.dart
│       └── presentation/
│           └── settings_page.dart
│
├── routes/
│   └── app_router.dart           # GoRouter or Navigator 2.0 setup
│
└── main.dart
```

---

## Tech Stack

| Concern | Package |
|---------|---------|
| UI Framework | Flutter (stable channel) |
| State Management | `riverpod` + `flutter_riverpod` |
| Database | `isar` |
| Secure Key Storage | `flutter_secure_storage` |
| Biometric Auth | `local_auth` |
| Audio Recording | `record` |
| Audio Playback | `just_audio` |
| Routing | `go_router` |
| Logging | Custom logger (no external analytics) |

---

## Dependency Injection

All dependencies are injected via Riverpod providers. No service locator patterns (`get_it`) are used. Providers are defined close to the feature they serve.

---

## Key Architecture Constraints

1. **No singleton state** — all state is managed through Riverpod providers
2. **Repository pattern** — data layer is always accessed through repository interfaces
3. **No direct Isar calls in presentation** — always go through use cases
4. **Encryption happens in the data layer** — domain entities always hold decrypted values
5. **Error propagation** — use `Either<Failure, T>` or `AsyncValue` consistently
