# 09 — Performance Guidelines

## Startup

- Target: App ready after biometric unlock in < 2 seconds on mid-range device
- Isar opens lazily after auth; do not block the lock screen with DB init
- Use `Isar.openAsync` — never block the main isolate on DB open

## Rendering

- No unbounded `ListView`; always use `ListView.builder`
- Entry list pagination: load 50 entries at a time
- Images (if added later): always use `CachedNetworkImage` with placeholder
- Avoid `setState` in large widget trees; scope rebuilds with Riverpod selectors

## Audio

- Load audio files lazily — only when entry is opened
- Do not preload all audio files on list scroll
- Stream amplitude data; do not buffer the whole recording in memory

## Animations

- Duration ≤ 200ms for transitions
- Prefer `AnimatedSwitcher` over custom `AnimationController` for simple cases
- Disable animations when `MediaQuery.disableAnimations` is true (accessibility)

## Battery

- No background services
- No periodic timers while in background
- Release audio resources (`dispose()`) when leaving the audio screen
