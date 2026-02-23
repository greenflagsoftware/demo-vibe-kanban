# Task 08 — Integration (`wp-spell` Assembler + Final Wiring)

## Execution Order
**RUN THIS LAST.** This task depends on all previous tasks being complete and passing.

**Prerequisites (must all be done and verified):**
- Task 00 — Foundation (`wp-common.sh`, session layer, test harness)
- Task 01 — `wp-spell-words`
- Task 02 — `wp-spell-lower`
- Task 03 — `wp-spell-unique`
- Task 04 — `wp-spell-mismatch` + `lib/dictionary.txt`
- Task 05 — `wp-stats`
- Task 06 — `wp-search`
- Task 07 — `wp-undo`

---

## Objective
Wire the five spell pipeline stages into the `wp-spell` top-level runner,
verify the full end-to-end pipeline, and ensure all components integrate
correctly through the session layer and the `wp` dispatcher.

---

## Deliverables

### 1. `bin/spell/wp-spell` — Spell Pipeline Assembler

This script assembles the five spell stages into one runnable command.

#### Interface
```bash
wp-spell [OPTIONS] [FILE]
```

If FILE is provided, read from it. Otherwise read from `session/current`.
If no session is active and no FILE is provided, exit 1 with a clear message.

#### Options

| Flag | Description |
|---|---|
| (none) | Print misspelled words to stdout, one per line |
| `-d FILE` | Use an alternate dictionary file |
| `-a WORD` | Add WORD to the dictionary, then exit |
| `--count` | Print only the count of misspelled words (integer) |
| `--no-commit` | Force read-only mode even if called through `wp run` |

#### Core pipeline implementation
```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DICT="${SCRIPT_DIR}/../../lib/dictionary.txt"
INPUT="${1:-}"

# resolve input source
if [[ -n "$INPUT" ]]; then
    SOURCE="$INPUT"
else
    source "${SCRIPT_DIR}/../../lib/wp-common.sh"
    SOURCE="$(wp_current)"
fi

cat "$SOURCE" \
    | "${SCRIPT_DIR}/wp-spell-words" \
    | "${SCRIPT_DIR}/wp-spell-lower" \
    | sort \
    | "${SCRIPT_DIR}/wp-spell-unique" \
    | "${SCRIPT_DIR}/wp-spell-mismatch" -d "$DICT"
```

#### Read-only behavior
`wp-spell` does not modify the document and does not call `wp_commit`.
It is a reporting tool only. This must hold true even when called via `wp run`.

---

### 2. Integration test: full spell pipeline

`tests/test-spell-integration.sh`

#### Test cases

| # | Description | Expected behavior |
|---|---|---|
| 1 | Document with no misspellings | No output, exit 0 |
| 2 | Document with 2 known misspellings | Both words output, one per line |
| 3 | Misspelled word in mixed case | Still caught (normalization working) |
| 4 | Word added via `-a`, re-run | Word no longer flagged |
| 5 | `--count` on document with 3 errors | Outputs `3` |
| 6 | Piped input with misspelling | Works without a session |
| 7 | Full pipeline manual invocation | Each stage can be called directly and chained |

Test case 7 must invoke the stages explicitly to verify each handoff:
```bash
echo "The kittne sat on the matt" \
  | bin/spell/wp-spell-words \
  | bin/spell/wp-spell-lower \
  | sort \
  | bin/spell/wp-spell-unique \
  | bin/spell/wp-spell-mismatch
```
Expected output: `kittne` and `matt` (and not `the`, `sat`, `on`).

---

### 3. End-to-end session integration test

`tests/test-e2e.sh`

Simulate a full editing session using all tools together:

```bash
# Setup
echo "The kittne sat on the matt. It was a grate day." > /tmp/test-doc.txt
wp init /tmp/test-doc.txt

# Spell check
ERRORS=$(wp pipe | bin/spell/wp-spell)
assert_contains "e2e: kittne flagged" "$ERRORS" "kittne"

# Fix a word
wp run wp-search "kittne" "kitten"
assert_eq "e2e: seq incremented" "2" "$(wp_seq)"

# Verify fix
ERRORS_AFTER=$(wp pipe | bin/spell/wp-spell)
# kittne should be gone
assert_not_contains "e2e: kittne resolved" "$ERRORS_AFTER" "kittne"

# Stats
WORDS=$(wp pipe | bin/wp-stats -w)
assert_eq "e2e: word count" "10" "$WORDS"

# Undo
wp-undo
assert_eq "e2e: undo restores seq" "1" "$(wp_seq)"

# Verify original error is back after undo
ERRORS_UNDONE=$(wp pipe | bin/spell/wp-spell)
assert_contains "e2e: error back after undo" "$ERRORS_UNDONE" "kittne"

# Cleanup
wp clean --force
```

Add `assert_not_contains` to `tests/harness.sh` if not already present.

---

### 4. `Makefile`

Provide a basic `Makefile` in the project root:

```makefile
.PHONY: test install clean

INSTALL_DIR ?= $(HOME)/.local/bin

test:
	@for t in tests/test-*.sh; do echo "--- $$t ---"; bash "$$t"; done

install:
	@mkdir -p $(INSTALL_DIR)
	@cp bin/wp bin/wp-search bin/wp-stats bin/wp-undo $(INSTALL_DIR)/
	@cp bin/spell/wp-spell $(INSTALL_DIR)/
	@echo "Installed to $(INSTALL_DIR)"

clean:
	@rm -rf session/
```

---

### 5. `README.md`

Complete the project README with:
- One-paragraph description of the project and its philosophy
- Prerequisites / dependencies table
- Quick start example (5–7 commands)
- Description of each tool (`wp`, `wp-search`, `wp-stats`, `wp-undo`, `wp-spell`)
- Dictionary maintenance instructions (adding words, re-sorting)
- How to run tests

---

## Final Acceptance Criteria

All of the following must pass before this task is considered complete:

```bash
# All unit tests
for t in tests/test-*.sh; do bash "$t"; done

# Integration test
bash tests/test-spell-integration.sh

# End-to-end test
bash tests/test-e2e.sh
```

- Every test script exits 0
- No `FAIL` lines appear in any test output
- `wp-spell` produces no output on a document containing only correctly spelled words
- `wp-search`, `wp-undo` each increment/decrement `wp_seq` correctly
- `wp-stats` and `wp-spell` never change `wp_seq`
