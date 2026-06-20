# Edge Cases — 07: UI State & Navigation

---

## EC-UI-01: Back Navigation During Active Recording

**Trigger:** User taps the back button while recording is in progress.  
**Risk:** Recording silently stops and the file is lost; or recording continues as a zombie with no UI.

**Handling:**
- Intercept back navigation using `PopScope` (Flutter 3.x) or `WillPopScope`
- Show a confirmation dialog: "You're currently recording. Stop and discard, or keep recording?"
  - "Keep Recording" — dismiss dialog, stay on page
  - "Stop and Save" — stop recording, save entry, navigate back
  - "Discard" — stop recording, delete temp file, navigate back
- Never silently discard a recording

---

## EC-UI-02: App Killed During Text Entry (No Save)

**Trigger:** OS kills app (memory pressure, crash) while user is mid-entry with no auto-save having fired yet.  
**Risk:** Entry content lost.

**Handling:**
- Auto-save triggers every 30 seconds while the user is typing
- Also auto-save on `AppLifecycleState.paused` (before app goes to background)
- For a brand-new entry: save as a draft (incomplete state) immediately on first keystroke
- On next launch: check for draft entries; present "You have an unsaved entry. Continue or discard?"

---

## EC-UI-03: Rapid Repeated Taps on Save

**Trigger:** User taps save multiple times quickly (network latency instinct).  
**Risk:** Duplicate entries created.

**Handling:**
- Debounce save action: ignore taps within 500ms of the previous save
- Show a loading indicator during save operation
- Disable the save button while a save is in progress

---

## EC-UI-04: Navigation to Deleted Entry

**Trigger:** User has the entry detail page open; entry is deleted from another navigation action (e.g., via search result → delete).  
**Risk:** Entry detail page tries to load a deleted entry; crashes or shows stale data.

**Handling:**
- Entry detail provider watches its specific entry by ID
- If the entry disappears from Isar (watch fires with null): automatically navigate back to the list
- Show a brief toast: "This entry was deleted"
- This scenario is unlikely but possible with fast navigation

---

## EC-UI-05: Entry List Scroll State Lost After Navigation

**Trigger:** User scrolls deep in the entry list, opens an entry, returns — list jumps back to top.  
**Risk:** Frustrating UX; user loses their place.

**Handling:**
- Store scroll position in the list page's Riverpod provider (not local widget state)
- Restore on return from entry detail
- Use `ScrollController` with a persistent key

---

## EC-UI-06: Keyboard Overlap Hides Writing Area

**Trigger:** On small devices or in landscape, the software keyboard covers the text input.  
**Risk:** User can't see what they're typing.

**Handling:**
- Wrap entry page in `Scaffold` with `resizeToAvoidBottomInset: true` (Flutter default — verify it's not disabled)
- Use `SingleChildScrollView` + `Expanded` pattern for the text area to push content above keyboard
- Test on iPhone SE (small screen) and landscape on 5" Android devices

---

## EC-UI-07: Search with Special Characters

**Trigger:** User searches for `"`, `'`, `%`, `_`, or emoji.  
**Risk:** Isar query crashes or returns wrong results.

**Handling:**
- Sanitize search query before passing to Isar: escape special characters
- Emoji search should work (Dart strings are UTF-16; Isar handles Unicode)
- Test queries: `"`, `\`, empty string, emoji-only, 1 character (show "type at least 2 characters"), 500+ characters

---

## EC-UI-08: Orientation Change During Recording

**Trigger:** User rotates device mid-recording.  
**Risk:** Widget tree rebuild destroys recording state.

**Handling:**
- `RecordingService` is a Riverpod provider, not widget state — survives widget rebuilds
- Recording continues through orientation changes
- Waveform/amplitude display re-initializes from the active stream; no gap in display

---

## EC-UI-09: Dark Mode Toggle Doesn't Apply Immediately

**Trigger:** User changes theme in settings; some screens still show old theme.  
**Risk:** Inconsistent visual state.

**Handling:**
- Theme is controlled by a `ThemeNotifier` Riverpod provider at `MaterialApp` level
- Changing the provider value triggers a full tree rebuild via `MaterialApp`'s `theme` and `darkTheme` bindings
- Theme change is immediate; no restart required
- Test: toggle in settings → navigate back → all screens updated

---

## EC-UI-10: Empty Search Query Submitted

**Trigger:** User clears the search field; results should reset.  
**Risk:** Empty query shows all entries (unexpected) or no results (confusing).

**Handling:**
- When query is empty or < 2 characters: clear results and show the prompt "Start typing to search your diary"
- Do not show all entries in the search view — that's the main list
