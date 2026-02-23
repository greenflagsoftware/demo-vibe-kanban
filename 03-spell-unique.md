# Task 03 — `wp-spell-unique` (Spell Pipeline Stage 4: Deduplicator)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 02, 04, 05, 06, 07.
Requires task 00 (Foundation) to be complete before this task begins.

## Note on Stage Numbering
This script is Stage 4 in the pipeline. Stage 3 is the system `sort` utility,
called directly — no wrapper script is needed for it.

Pipeline order: words → lower → **sort** → unique → mismatch

---

## ⚠️ Branch Isolation Rules
This task runs on its own git branch. To prevent merge conflicts, observe the
following strictly:

**READ-ONLY — do not edit these files (created by task 00):**
- `lib/wp-common.sh` — source it, never modify it
- `tests/harness.sh` — source it, never modify it
- `bin/wp` — do not touch

**Files this task owns (create these, no other task will touch them):**
- `bin/spell/wp-spell-unique`
- `tests/test-spell-unique.sh`

If you discover that `lib/wp-common.sh` is missing a function you need,
do NOT add it yourself. Note it as a TODO comment in your script and flag it
in your task completion report for task 08 (Integration) to resolve.

---

## Objective
Implement `bin/spell/wp-spell-unique` — the fourth stage of the spell-check pipeline.
It reads a sorted list of words (one per line) from stdin and emits the list with
consecutive duplicate lines removed.

---

## Rationale
Common words like "the" and "and" may appear hundreds of times in a document.
This stage ensures each unique word is checked against the dictionary exactly once.

**Important:** This stage only works correctly when its input is already sorted.
It relies on `sort` (Stage 3) having been applied immediately before it in the pipeline.
`uniq` only removes *adjacent* duplicates — non-adjacent duplicates would be missed
without the preceding sort.

---

## Behavior

### Input
A sorted list of words, one per line, all lowercase (output of Stage 3: `sort`).

### Output
The same list with consecutive duplicate lines removed. Each unique word appears
exactly once. Order is preserved.

### Examples

```
Input:          Output:
cat             cat
cat             dog
dog             fox
dog             the
fox
the
the
the
```

---

## Implementation

### Backing tool
`uniq`

### Implementation
```bash
uniq
```

### Why not `sort -u`?
Combining sort and deduplication into one step would eliminate Stage 3 and
Stage 4 as independent, swappable components. Keeping them separate preserves
modularity: either stage can be replaced or inspected in isolation.

---

## File Location
`bin/spell/wp-spell-unique`

Must be executable (`chmod +x`).

---

## Script skeleton
```bash
#!/usr/bin/env bash
set -euo pipefail
uniq
```

---

## Test File
`tests/test-spell-unique.sh`

Source the harness as read-only:
```bash
source "$(dirname "$0")/harness.sh"
```

### Required test cases

| # | Input lines | Expected output lines |
|---|---|---|
| 1 | `cat cat dog` (one per line) | `cat dog` |
| 2 | `the the the` | `the` |
| 3 | no duplicates: `apple berry cat` | `apple berry cat` (unchanged) |
| 4 | single word repeated 100 times | that word once |
| 5 | empty input | no output, exit 0 |

Call `report` at the end of the test script.

---

## Acceptance Criteria
- `bash tests/test-spell-unique.sh` exits 0, all cases PASS
- Script is ≤ 5 lines including shebang and set flags
- Script produces no output to stderr during normal operation
- Output word count is always ≤ input word count
- This task's branch touches exactly two files: `bin/spell/wp-spell-unique` and `tests/test-spell-unique.sh`
