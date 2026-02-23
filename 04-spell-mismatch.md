# Task 04 — `wp-spell-mismatch` (Spell Pipeline Stage 5: Dictionary Comparator)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 02, 03, 05, 06, 07.
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
- `bin/spell/wp-spell-mismatch`
- `lib/dictionary.txt`
- `tests/test-spell-mismatch.sh`
- `tests/fixtures/test-dict.txt`

If you discover that `lib/wp-common.sh` is missing a function you need,
do NOT add it yourself. Note it as a TODO comment in your script and flag it
in your task completion report for task 08 (Integration) to resolve.

---

## Objective
Implement `bin/spell/wp-spell-mismatch` and provision `lib/dictionary.txt`.

`wp-spell-mismatch` is the fifth and final stage of the spell-check pipeline.
It compares the processed word list from stdin against the master dictionary
and prints only the words not found in the dictionary — the potential misspellings.

---

## Deliverables

### 1. `bin/spell/wp-spell-mismatch`

#### Behavior

**Input:** A sorted, deduplicated, lowercased list of words on stdin
(output of Stage 4: `wp-spell-unique`).

**Positional argument:** Path to the dictionary file (default: `lib/dictionary.txt`
resolved relative to the script's own location).

**Output:** One word per line — words present in the document but absent from
the dictionary. If there are no misspellings, produces no output and exits 0.

#### Implementation

**Backing tool:** `comm`

```bash
comm -23 - "$DICT_FILE"
```

- `comm` compares two **sorted** files line by line
- `-2` suppresses lines found only in the dictionary
- `-3` suppresses lines found in both files
- Column 1 (remaining output) is words in stdin only — not in the dictionary
- The `-` argument reads stdin as the first file

#### Flags

| Flag | Description |
|---|---|
| `-d FILE` | Use an alternate dictionary file instead of the default |
| `-a WORD` | Append WORD to the dictionary and re-sort it, then exit |

#### `comm` input requirements
Both the stdin word list and the dictionary file **must** be sorted for `comm`
to produce correct results. The pipeline guarantees the word list is sorted
(Stage 3). The dictionary must be maintained in sorted order (see below).

#### Script skeleton
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DICT="${SCRIPT_DIR}/../../lib/dictionary.txt"

# parse -d and -a flags here

comm -23 - "$DICT"
```

---

### 2. `lib/dictionary.txt`

A plain UTF-8 text file. One lowercase word per line. Sorted alphabetically.

#### Provisioning
Seed the dictionary from the system word list:

```bash
cat /usr/share/dict/words \
  | tr 'A-Z' 'a-z' \
  | grep -E '^[a-z]+$' \
  | sort -u \
  > lib/dictionary.txt
```

The `grep` filter removes entries with apostrophes, hyphens, or digits
to keep the dictionary simple and uniform. If `/usr/share/dict/words` is not
available, document the required install command
(`sudo apt-get install wamerican` on Debian/Ubuntu) in a comment at the top
of `tests/test-spell-mismatch.sh`.

#### Maintenance rules
- All words must be lowercase
- File must remain sorted at all times
- To add a word: `echo "tinkerer" >> lib/dictionary.txt && sort -o lib/dictionary.txt lib/dictionary.txt`
- The `-a` flag in `wp-spell-mismatch` automates this

---

### 3. `tests/fixtures/test-dict.txt`

A small, controlled dictionary for use in tests only (not the full system word list).
This ensures tests are deterministic and fast regardless of the system dictionary.

Suggested content (sorted, one word per line):
```
cat
dog
fox
jumps
lazy
over
quick
sat
the
```

---

## File Locations
- `bin/spell/wp-spell-mismatch` (executable)
- `lib/dictionary.txt`
- `tests/test-spell-mismatch.sh`
- `tests/fixtures/test-dict.txt`

---

## Test File
`tests/test-spell-mismatch.sh`

Source the harness as read-only:
```bash
source "$(dirname "$0")/harness.sh"
```

All tests must use `tests/fixtures/test-dict.txt` as the dictionary, not
`lib/dictionary.txt`, to ensure deterministic results.

### Required test cases

| # | Description | Expected behavior |
|---|---|---|
| 1 | All words in test dictionary | No output, exit 0 |
| 2 | One misspelled word `kittne` | Outputs `kittne` |
| 3 | Two misspelled words | Both output, one per line |
| 4 | Empty input | No output, exit 0 |
| 5 | `-a` flag adds word to a temp copy of the dictionary | Word no longer flagged in subsequent run |
| 6 | `-d` flag uses alternate dictionary | Respects the alternate file |

For test case 5, copy `tests/fixtures/test-dict.txt` to a temp file before
testing `-a` so the fixture is never permanently modified.

Call `report` at the end of the test script.

---

## Acceptance Criteria
- `bash tests/test-spell-mismatch.sh` exits 0, all cases PASS
- `lib/dictionary.txt` exists, is sorted, contains only lowercase alpha words
- `echo "kittne" | bin/spell/wp-spell-mismatch -d tests/fixtures/test-dict.txt` outputs `kittne`
- `echo "the" | bin/spell/wp-spell-mismatch -d tests/fixtures/test-dict.txt` produces no output
- This task's branch touches exactly these files: `bin/spell/wp-spell-mismatch`, `lib/dictionary.txt`, `tests/test-spell-mismatch.sh`, `tests/fixtures/test-dict.txt`
