# Task 02 — `wp-spell-lower` (Spell Pipeline Stage 2: Normalizer)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 03, 04, 05, 06, 07.
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
- `bin/spell/wp-spell-lower`
- `tests/test-spell-lower.sh`

If you discover that `lib/wp-common.sh` is missing a function you need,
do NOT add it yourself. Note it as a TODO comment in your script and flag it
in your task completion report for task 08 (Integration) to resolve.

---

## Objective
Implement `bin/spell/wp-spell-lower` — the second stage of the spell-check pipeline.
It reads a list of words (one per line) from stdin and emits all words converted to
lowercase on stdout.

---

## Rationale
Dictionaries store words in lowercase. Without normalization, correctly spelled words
that appear at the start of sentences ("The", "A") or as proper nouns ("Unix", "Bell")
would be flagged as misspellings. This stage ensures all tokens are in canonical
form before dictionary comparison.

---

## Behavior

### Input
One word per line (output of `wp-spell-words`). May be mixed case.

### Output
One word per line, all characters converted to lowercase.
Line count in == line count out. No lines are added or removed.

### Examples

```
Input:          Output:
The             the
Quick           quick
Brown           brown
UNIX            unix
```

---

## Implementation

### Backing tool
`tr`

### Implementation
```bash
tr 'A-Z' 'a-z'
```

This is intentionally the simplest possible implementation.
Do not use `awk`, `sed`, or `python` — `tr` is the correct tool for this job.

---

## File Location
`bin/spell/wp-spell-lower`

Must be executable (`chmod +x`).

---

## Script skeleton
```bash
#!/usr/bin/env bash
set -euo pipefail
tr 'A-Z' 'a-z'
```

---

## Test File
`tests/test-spell-lower.sh`

Source the harness as read-only:
```bash
source "$(dirname "$0")/harness.sh"
```

### Required test cases

| # | Input | Expected output |
|---|---|---|
| 1 | `Hello` | `hello` |
| 2 | `UNIX` | `unix` |
| 3 | `already` | `already` |
| 4 | `MiXeD` | `mixed` |
| 5 | empty string | no output, exit 0 |
| 6 | three words on three lines | three lowercase words on three lines |

Call `report` at the end of the test script.

---

## Acceptance Criteria
- `bash tests/test-spell-lower.sh` exits 0, all cases PASS
- Script is ≤ 5 lines including shebang and set flags
- Script produces no output to stderr during normal operation
- Line count of input equals line count of output for non-empty input
- This task's branch touches exactly two files: `bin/spell/wp-spell-lower` and `tests/test-spell-lower.sh`
