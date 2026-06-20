# 08 — Search System

## Design

Search is local-only, synchronous for small datasets, and index-backed for large ones.

---

## Flow

1. User types query (minimum 2 characters)
2. 300ms debounce fires
3. Search use case queries Isar
4. Results decrypted in memory
5. Snippets extracted and returned
6. UI updates with results list

---

## Isar Search Implementation

Text entries use Isar's built-in full-text search via `@Index(type: IndexType.value)`. Since text is stored encrypted, the search approach must be:

**Option A — Decrypt-then-search (MVP approach):**
- On search query, load all entries, decrypt each, filter in memory
- Suitable for < 500 entries (expected MVP usage)
- No index needed on encrypted field

**Option B — Shadow plaintext index (post-MVP):**
- Store a second tokenized index field (stripped of full content)
- Search the index, decrypt only matching entries
- Required if entry count grows beyond ~1,000

**MVP decision: Use Option A.** Flag for migration to Option B at 500+ entry milestone.

---

## Result Format

```dart
class SearchResult {
  final DiaryEntry entry;
  final String snippet;       // ~100 chars around match, with match highlighted
  final int matchCount;
}
```

---

## What is Searchable

| Content | Searchable? |
|---------|------------|
| Text entry content | ✅ |
| Entry date | ✅ (search "march 2024") |
| Audio transcript | ❌ (post-MVP) |
| Audio file name | ❌ |
