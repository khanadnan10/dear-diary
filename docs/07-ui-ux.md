# 07 — UI/UX Principles

## Design Philosophy

The interface should feel like a private notebook — calm, focused, slightly analog in feeling. No chrome. No clutter. Nothing pulling the user's attention away from writing.

---

## Core Screens

| Screen | Purpose |
|--------|---------|
| Lock Screen | Biometric/PIN prompt — minimal, no app branding leak |
| Entry List | Chronological list of entries; home screen |
| Text Entry | Full-screen writing experience |
| Audio Entry | Record or playback; minimal controls |
| Search | Search bar + results |
| Settings | Theme, timeout, about |

---

## Visual Language

| Property | Specification |
|----------|--------------|
| Primary font | System font (SF Pro on iOS, Roboto on Android) |
| Base font size | 16sp body, 14sp secondary |
| Line height | 1.6× for reading comfort |
| Corner radius | 12dp cards, 8dp inputs |
| Animation duration | 200ms max; no bouncy spring animations |
| Dark mode default | Soft dark (`#1A1A1A` background, not pure black) |
| Light mode | Off-white (`#F5F5F0`), not pure white |

---

## What Not to Build

- ❌ No bottom navigation with icons
- ❌ No floating action button with a complex menu
- ❌ No home screen dashboard/stats
- ❌ No modal sheets stacked more than 2 levels deep
- ❌ No swipe-to-reveal with more than 2 actions
- ❌ No loading spinners on anything under 300ms

---

## Responsive Design

```dart
// Use LayoutBuilder everywhere
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return TabletLayout();
    }
    return PhoneLayout();
  },
)
```

- **Phone (< 600dp):** Full-width single-column layout
- **Tablet (≥ 600dp):** Master-detail: entry list on left, entry on right
- Max content width on tablet: 720dp (centered)
- Use `EdgeInsets.symmetric(horizontal: max(16, (width - 720) / 2))` for centering

---

## Accessibility

- Minimum tap target: 48×48dp
- All interactive elements have semantic labels
- High-contrast text ratios (WCAG AA minimum)
- `ExcludeSemantics` on purely decorative elements
- VoiceOver/TalkBack tested before release

---

## App Switcher Privacy

The app switcher must not show entry content. Implementation:
- **Android:** `FLAG_SECURE` always active
- **iOS:** Overlay a blur/logo view on `applicationWillResignActive`

---

## Empty States

| Screen | Empty state message |
|--------|-------------------|
| Entry List | "Nothing here yet. Tap + to start." |
| Search results | "No entries match your search." |

No illustrations, no motivational quotes. Just clean text.
