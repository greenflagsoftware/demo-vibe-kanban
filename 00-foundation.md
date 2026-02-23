# Task 00 — Foundation (Session Layer + Shared Library + Test Harness)

## Execution Order
**RUN THIS FIRST.** All other tasks depend on the artifacts produced here.
Do not begin any other task until this one is complete and verified.

## Objective
Establish the repository skeleton, shared shell library (`wp-common.sh`),
session directory structure, and the test harness used by all other tasks.

---

## Deliverables

### 1. Repository Skeleton

Create the following directory structure (empty placeholder files where noted):

```
wp/
├── bin/
│   └── spell/
├── lib/
├── session/         ← created at runtime by `wp init`, not committed to repo
├── tests/
└── README.md        ← one-line placeholder is fine
```

### 2. `lib/wp-common.sh`

A sourced (not executed) bash library. All functions must be prefixed `wp_`.

#### Required functions:

**`wp_session_dir`**
- Prints the absolute path to the active session directory
- Session dir is `$WP_SESSION` if set, otherwise `./session`
- Does not create the directory

**`wp_current`**
- Prints the resolved path of `session/current` (the active snapshot file)
- Exits with error code 1 and a message to stderr if `session/current` does not exist

**`wp_commit`**
- Reads stdin, writes it to the next numbered snapshot in `session/history/`
- Snapshot filenames are zero-padded to 4 digits: `0001.txt`, `0002.txt`, etc.
- Updates `session/current` symlink to point to the new snapshot
- Increments the sequence counter stored in `session/meta`
- `session/meta` format (plain text, one key=value per line):
  ```
  seq=0003
  source=draft.txt
  ```

**`wp_seq`**
- Prints the current sequence number as a plain integer (e.g. `3`)

**`wp_log`**
- Usage: `wp_log LEVEL "message"`
- LEVEL is one of: `INFO`, `WARN`, `ERR`
- Writes to stderr only, never stdout (stdout is reserved for filter output)
- Colorize output using ANSI codes: INFO=green, WARN=yellow, ERR=red
- Format: `[LEVEL] message`

**`wp_require_cmd`**
- Usage: `wp_require_cmd cmd1 cmd2 ...`
- For each argument, checks that the command exists via `command -v`
- If any are missing, prints an ERR log and exits with code 127

**`wp_escape_sed`**
- Usage: `wp_escape_sed "some/string.with[special]chars"`
- Prints the string with `/`, `.`, `[`, `]`, `*`, `^`, `$`, `\` escaped for use in a sed expression

### 3. `bin/wp` — Main Dispatcher

A bash script implementing the following subcommands:

| Subcommand | Behavior |
|---|---|
| `wp init <file>` | Creates `session/`, `session/history/`, copies `<file>` to `session/history/0001.txt`, creates `session/current` symlink, writes `session/meta` |
| `wp save [outfile]` | Copies `session/current` to `outfile` (default: original source filename from meta) |
| `wp run <script> [args]` | Pipes `session/current` through `bin/<script> [args]`, result goes to `wp_commit` |
| `wp pipe` | Cats `session/current` to stdout |
| `wp status` | Prints session source filename, current snapshot number, word count of current snapshot |
| `wp clean` | Removes the entire `session/` directory after prompting for confirmation |

Error handling requirements:
- `wp init` must fail with a clear message if the file does not exist
- All subcommands except `init` must fail clearly if no session exists
- Unknown subcommands print usage and exit 1

### 4. `tests/harness.sh`

A sourced helper library for all test scripts.

#### Required functions:

**`assert_eq DESCRIPTION EXPECTED ACTUAL`**
- Prints `PASS: DESCRIPTION` if EXPECTED == ACTUAL
- Prints `FAIL: DESCRIPTION` with a diff if they differ
- Increments global counters `TESTS_PASSED` and `TESTS_FAILED`

**`assert_contains DESCRIPTION HAYSTACK NEEDLE`**
- Passes if NEEDLE is a substring of HAYSTACK

**`assert_exit_code DESCRIPTION EXPECTED_CODE ACTUAL_CODE`**
- Passes if exit codes match

**`report`**
- Prints summary: `Results: X passed, Y failed`
- Exits with code 0 if all passed, 1 if any failed

### 5. `tests/test-foundation.sh`

Tests for the foundation layer itself:

- `wp init` creates expected directory structure
- `wp_commit` increments sequence correctly
- `wp_current` fails gracefully when no session exists
- `wp save` writes the correct content
- `wp clean` removes the session directory

---

## Acceptance Criteria

- `bash tests/test-foundation.sh` exits 0 with all PASS
- `source lib/wp-common.sh` produces no output and no errors
- `wp init nonexistent.txt` exits non-zero with a message on stderr
- All functions in `wp-common.sh` are documented with an inline comment

## Notes for Agent
- Use `#!/usr/bin/env bash` shebangs
- Set `set -euo pipefail` at the top of all executable scripts
- Do not use any external tools beyond standard GNU coreutils
- Do not hardcode absolute paths — use `$(dirname "$0")` or `$SCRIPT_DIR` patterns
