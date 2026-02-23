# Task 05 — `wp-stats` (Word, Line & Character Statistics)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 02, 03, 04, 06, 07.
Requires task 00 (Foundation) to be complete before this task begins.

---

## ⚠️ Branch Isolation Rules
This task runs on its own git branch. To prevent merge conflicts, observe the
following strictly:

**READ-ONLY — do not edit these files (created by task 00):**
- `lib/wp-common.sh` — source it, never modify it
- `tests/harness.sh` — source it, never modify it
- `bin/wp` — do not touch

**Files this task owns (create these, no other task will touch them):**
- `bin/wp-stats`
- `lib/stopwords.txt`
- `tests/test-stats.sh`
- `tests/fixtures/sample.txt`

If you discover that `lib/wp-common.sh` is missing a function you need,
do NOT add it yourself. Note it as a TODO comment in your script and flag it
in your task completion report for task 08 (Integration) to resolve.

---

## Objective
Implement `bin/wp-stats` — a read-only filter that computes and displays
document statistics. It reads from stdin and writes a formatted report to stdout.
It never modifies the document and never calls `wp_commit`.

---

## Interface

```bash
wp-stats [OPTIONS] [FILE]
```

If FILE is provided, read from it. Otherwise read from stdin.

### Options

| Flag | Description |
|---|---|
| (none) | Full report — all statistics |
| `-w` | Word count only (raw integer) |
| `-l` | Line count only |
| `-c` | Character count only |
| `-s` | Sentence count only |
| `-p` | Paragraph count only |
| `--freq N` | Top N most frequent non-stopword words |
| `--avg` | Average word length and words-per-sentence |

When a single stat flag is used alone, output is a plain integer with no label
(suitable for use in pipelines). When multiple flags are combined, or no flags
are given, output is a labeled table.

---

## Statistics Definitions

### Word count
`wc -w`

### Line count
`wc -l`

### Character count
`wc -m` (counts Unicode characters, not bytes)

### Sentence count
Count occurrences of `.`, `!`, or `?` that are followed by whitespace or end of line:
```bash
grep -oE '[.!?](\s|$)' | wc -l
```

### Paragraph count
Paragraphs are delimited by one or more blank lines:
```bash
awk 'BEGIN{p=1} /^[[:space:]]*$/{if(!b){p++; b=1}} /[^[:space:]]/{b=0} END{print p}'
```
A document with no blank lines is one paragraph.

### Word frequency
```bash
tr -cs 'A-Za-z' '\n' \
  | tr 'A-Z' 'a-z' \
  | grep -vFf "$SCRIPT_DIR/../lib/stopwords.txt" \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -"$N" \
  | awk '{printf "  %-20s %d\n", $2, $1}'
```

### Average word length
Total characters in all words divided by word count, computed via `awk`:
```bash
awk '{ total += length($0); count++ } END { printf "%.2f\n", total/count }'
```
applied to the one-word-per-line stream.

### Average words per sentence
Word count divided by sentence count.

---

## Full Report Format

```
──────────────────────────────
 Document Statistics
──────────────────────────────
 Lines           :      142
 Words           :    1,847
 Characters      :    9,203
 Sentences       :       89
 Paragraphs      :       18
 Avg word length :     4.98
 Avg words/sent  :    20.75
──────────────────────────────
```

Numbers are right-aligned. Thousands are comma-separated.
Use `printf` and `awk` for formatting — do not use `bc`.

---

## `lib/stopwords.txt`

A plain text file, one word per line, for use with `grep -Ff`.
Include at minimum:
```
a
an
and
are
as
at
be
been
but
by
for
if
in
is
it
of
on
or
the
to
was
were
with
```
Expand to at least 50 common English stopwords.

---

## `tests/fixtures/sample.txt`

A controlled test document with known, predictable statistics.
Design it so the expected values are easy to verify manually.
Suggested structure: 3 paragraphs, exactly 50 words, 5 sentences.

---

## File Locations
- `bin/wp-stats` (executable)
- `lib/stopwords.txt`
- `tests/test-stats.sh`
- `tests/fixtures/sample.txt`

---

## Test File
`tests/test-stats.sh`

Source the harness as read-only:
```bash
source "$(dirname "$0")/harness.sh"
```

All tests should use `tests/fixtures/sample.txt` as input for determinism.

### Required test cases

| # | Description | Expected behavior |
|---|---|---|
| 1 | Known input, `-w` flag | Correct word count integer |
| 2 | Known input, `-l` flag | Correct line count integer |
| 3 | Known input, `-s` flag | Correct sentence count |
| 4 | Known input, `-p` flag | Correct paragraph count |
| 5 | `--freq 3` on known input | Top 3 non-stopwords listed |
| 6 | Empty input | Outputs zeros, exits 0 |
| 7 | Single word, no newline | Word count = 1 |

Call `report` at the end of the test script.

---

## Acceptance Criteria
- `bash tests/test-stats.sh` exits 0, all cases PASS
- `-w` flag outputs a plain integer with no label
- `wp-stats` never modifies `session/` — source `lib/wp-common.sh` read-only if needed to verify
- Report is readable in an 80-column terminal
- This task's branch touches exactly these files: `bin/wp-stats`, `lib/stopwords.txt`, `tests/test-stats.sh`, `tests/fixtures/sample.txt`
