# Task 07 — `wp-undo` (History & Undo)

## Execution Order
**Parallel batch.** May run concurrently with tasks 01, 02, 03, 04, 05, 06.
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
- `bin/wp-undo`
- `tests/test-undo.sh`

**Permitted use of foundation files:**
`bin/wp-undo` must source `lib/wp-common.sh` to call `wp_session_dir`,
`wp_current`, `wp_seq`, and `wp_log`. Source it read-only at the top:
```bash
source "$(dirname "${BASH_SOURCE[0]}")/../lib/wp-common.sh"
```
Do not add, remove, or modify any function in `wp-common.sh`.

If a required function is missing from `lib/wp-common.sh`, implement it as a
local function with the prefix `_undo_` and add a TODO comment directing task
08 to migrate it to `wp-common.sh`.

---

## Objective
Implement `bin/wp-undo` — the history navigation tool. It manipulates the
`session/current` symlink and `session/meta` sequence counter to move backward
(or to a specific point) in the document's snapshot history.

`wp-undo` never modifies the content of any snapshot file. It only moves the
pointer that identifies which snapshot is "current."

---

## Interface

```bash
wp-undo [OPTIONS]
```

### Options

| Flag | Description |
|---|---|
| (none) | Step back one snapshot |
| `-n N` | Step back N snapshots |
| `--list` | Print full history with sequence number, timestamp, and word count |
| `--diff N` | Show a colored diff between current snapshot and N steps back |
| `--jump N` | Restore snapshot number N absolutely (ignores current position) |
| `--prune N` | Delete all snapshots older than the most recent N; cannot be undone |

---

## Implementation

### Step back (default and `-n`)
1. Read current sequence number via `wp_seq`
2. Compute target: `target = current_seq - N`
3. If `target < 1`: print error "Already at oldest snapshot", exit 1
4. Update symlink: `ln -sfn "history/$(printf '%04d' $target).txt" "$(wp_session_dir)/current"`
5. Update `seq=` in `session/meta` to the target value using `sed -i`

### `--list`
For each file in `session/history/` in ascending order:
```
  [0001]  2024-11-01 14:22:03  312 words
  [0002]  2024-11-01 14:35:17  289 words   ← current
  [0003]  2024-11-01 15:01:44  301 words
```
- Use `stat --format='%y'` to get modification time
- Use `wc -w` for word count
- Mark the current snapshot with `← current`
- Use `printf` for column alignment

### `--diff N`
1. Identify current snapshot path and the snapshot N steps back
2. Run: `diff --color=always <(cat target_snapshot) <(cat current_snapshot)`
3. If `delta` is available (`command -v delta`), pipe through `delta` instead
4. Exit with diff's exit code (1 = differences found, 0 = identical)

### `--jump N`
1. Validate that `session/history/$(printf '%04d' N).txt` exists
2. Update symlink and meta to point to N
3. Print confirmation to stderr: `Restored snapshot 0003`

### `--prune N`
1. Find all snapshots with sequence number < (max_seq - N)
2. Prompt on stderr: `About to delete X snapshots. Continue? [y/N]`
3. Read response from `/dev/tty` (not stdin, which may be a pipe)
4. If confirmed, delete the files; otherwise exit 0
5. Do not renumber remaining snapshots

---

## File Location
`bin/wp-undo` (executable)

---

## Edge Cases
- Step back when already at snapshot 1: error, exit 1, session unchanged
- `--jump` to a non-existent snapshot: error, exit 1
- `--diff` when only one snapshot exists: "Nothing to diff", exit 0
- `--prune` with N ≥ total snapshot count: "Nothing to prune", exit 0
- `--prune` answered 'N': exit 0, nothing deleted

---

## Test File
`tests/test-undo.sh`

Source the harness as read-only:
```bash
source "$(dirname "$0")/harness.sh"
```

All tests must set up a temporary session using `export WP_SESSION=$(mktemp -d)`
and populate it with multiple known snapshots manually before running assertions.
Clean up with `rm -rf "$WP_SESSION"` after each test (use `trap` for safety).
Do not use or modify any existing `session/` directory in the repo.

### Required test cases

| # | Description | Expected behavior |
|---|---|---|
| 1 | Step back once from snapshot 3 | `wp_seq` becomes 2 |
| 2 | Step back `-n 2` from snapshot 4 | `wp_seq` becomes 2 |
| 3 | Step back from snapshot 1 | Exit 1, error on stderr, seq unchanged |
| 4 | `--list` shows all snapshots | Output contains sequence numbers and word counts |
| 5 | `--jump 2` from snapshot 4 | `wp_seq` becomes 2 |
| 6 | `--jump` to non-existent snapshot | Exit 1, session unchanged |
| 7 | `--diff 1` between two known snapshots | Output contains diff markers |

Call `report` at the end of the test script.

---

## Acceptance Criteria
- `bash tests/test-undo.sh` exits 0, all cases PASS
- `wp-undo` never modifies the content of any snapshot file
- `session/current` always resolves to a real, existing file after any operation
- `--list` output is readable in an 80-column terminal
- This task's branch touches exactly two files: `bin/wp-undo` and `tests/test-undo.sh`
