# Task 06 — `wp-search` (Search & Replace Filter)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 02, 03, 04, 05, 07.
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
- `bin/wp-search`
- `tests/test-search.sh`

**Permitted use of foundation files:**
`bin/wp-search` must source `lib/wp-common.sh` to call `wp_commit` and
`wp_escape_sed`. Source it read-only at the top of the script:
```bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/wp-common.sh"
```
Do not add, remove, or modify any function in `wp-common.sh`.

If `wp_escape_sed` is not yet present in `lib/wp-common.sh` when you test,
implement escaping inline in `bin/wp-search` as a local function and add a
TODO comment directing task 08 to migrate it to `wp-common.sh`.

---

## Objective
Implement `bin/wp-search` — a mutating filter that performs search and replace
on document text. It reads from stdin, applies a substitution, writes the result
to stdout, and calls `wp_commit` to snapshot the change.

---

## Interface

```bash
wp-search [OPTIONS] PATTERN REPLACEMENT
```

Input is always stdin. Output is always stdout.

### Options

| Flag | Description |
|---|---|
| `-i` | Case-insensitive matching |
| `-g` | Replace all occurrences per line (default behavior) |
| `-n N` | Replace only the Nth occurrence globally |
| `-r` | PATTERN is an extended regular expression (ERE) |
| `-p` | Preview mode: show a colored diff, do not commit |

### Arguments
- `PATTERN` — the text or regex to search for
- `REPLACEMENT` — the text to substitute in

---

## Implementation

### Backing tool
`sed`

### Core substitution
```bash
sed -E "s|${ESCAPED_PATTERN}|${ESCAPED_REPLACEMENT}|g"
```

Use `|` as the sed delimiter to avoid conflicts with `/` in patterns.
Still escape `|` characters within the pattern itself.

### Inline escape function (if `wp_escape_sed` is unavailable)
If `wp_escape_sed` is not present in `lib/wp-common.sh`, define it locally:
```bash
_escape_sed() {
    printf '%s' "$1" | sed 's/[|&\\.^$*[]/\\&/g'
}
```
Add a TODO: `# TODO task-08: migrate _escape_sed to lib/wp-common.sh as wp_escape_sed`

### Case-insensitive flag
Append `I` to the sed flags: `s|pattern|replacement|gI`

### Nth occurrence (`-n N`)
Use sed's occurrence modifier: `s|pattern|replacement|N`
This replaces only the Nth occurrence per line. Document this behavior in `--help`.

### Preview mode (`-p`)
1. Apply substitution to a temp file: `TMPFILE=$(mktemp)`
2. Run the sed expression and write to `TMPFILE`
3. Display: `diff --color=always "$(wp_current)" "$TMPFILE"`
4. Remove `TMPFILE` on exit via `trap "rm -f $TMPFILE" EXIT`
5. Do not call `wp_commit`

### Session integration
After performing the substitution in normal (non-preview) mode:
```bash
cat "$(wp_current)" | sed ... | wp_commit
```

---

## File Location
`bin/wp-search` (executable)

---

## Error handling
- PATTERN or REPLACEMENT not provided: print usage to stderr, exit 1
- Malformed regex: print the sed error to stderr, exit with sed's exit code
- No active session and no FILE: print a clear message, exit 1

---

## Test File
`tests/test-search.sh`

Source the harness as read-only:
```bash
source "$(dirname "$0")/harness.sh"
```

Tests that exercise `wp_commit` must initialize a temporary session and clean
it up afterward. Do not use or modify any existing `session/` directory.
Use a temp dir: `export WP_SESSION=$(mktemp -d)` and `rm -rf "$WP_SESSION"` on cleanup.

### Required test cases

| # | Description | Expected behavior |
|---|---|---|
| 1 | Simple literal replace | "cat" → "dog" in known input |
| 2 | Case-insensitive `-i` | "Cat", "CAT", "cat" all replaced |
| 3 | ERE pattern `-r` | Regex `\b(Mr\|Mrs)\.\b` → `Mx.` |
| 4 | `-n 2` flag | Only the 2nd occurrence replaced |
| 5 | Preview mode `-p` | Output contains diff markers, session seq unchanged |
| 6 | Pattern with `/` character | Does not break the sed expression |
| 7 | No match | Input passes through unchanged, exit 0 |
| 8 | Empty input | No output, exit 0 |

Call `report` at the end of the test script.

---

## Acceptance Criteria
- `bash tests/test-search.sh` exits 0, all cases PASS
- After a non-preview run, `wp_seq` is incremented by 1
- After a preview run, `wp_seq` is unchanged
- Script handles patterns containing `/`, `[`, `]`, `*`, `\` without crashing
- This task's branch touches exactly two files: `bin/wp-search` and `tests/test-search.sh`
