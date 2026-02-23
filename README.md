# wp-kanban — Word Processing Kanban Tools

A minimalist Unix-style word processing toolkit built around a session-based workflow. The philosophy is simple: treat documents as immutable snapshots, compose small single-purpose tools via pipes, and maintain a complete history of every change. This approach enables powerful workflows using standard Unix conventions while providing safety through versioned snapshots.

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| Bash | 4.0+ | Required for all scripts |
| coreutils | — | `cat`, `sort`, `uniq`, `wc`, etc. |
| grep | — | For pattern matching |
| sed | — | For text transformations |
| awk | — | For text processing |
| comm | — | For dictionary comparison |

## Quick Start

```bash
# 1. Initialize a session with your document
wp init my-document.txt

# 2. Check for misspelled words
wp pipe | wp-spell

# 3. Search and replace a misspelled word
wp run wp-search "kittne" "kitten"

# 4. View document statistics
wp pipe | wp-stats

# 5. Undo the last change
wp-undo

# 6. Save your work
wp save

# 7. Clean up when done
wp clean
```

## Tools

### `wp` — Main Dispatcher

The central command for managing editing sessions.

```bash
wp init <file>       # Initialize a new session with the given file
wp save [outfile]    # Save current snapshot to outfile (default: original source)
wp run <script>      # Pipe current snapshot through bin/<script>, commit result
wp pipe              # Output current snapshot to stdout
wp status            # Show session info (source, snapshot number, word count)
wp clean             # Remove the session directory (with confirmation)
```

### `wp-search` — Search and Replace

Performs search and replace operations on text from stdin.

```bash
wp-search <pattern> <replacement>
```

Reads from stdin, replaces all occurrences of `<pattern>` with `<replacement>`, outputs to stdout.

### `wp-stats` — Document Statistics

Computes and displays document statistics.

```bash
wp-stats [OPTIONS] [FILE]

Options:
  -w          Show word count only
  -l          Show line count only
  -c          Show character count only
  -s          Show sentence count only
  -p          Show paragraph count only
  --freq N    Show top N most frequent words
  --avg       Show average word length and words per sentence
```

### `wp-undo` — Undo Last Change

Reverts to the previous snapshot in the session history.

```bash
wp-undo
```

Decrements the session sequence and updates the `current` symlink to point to the previous snapshot.

### `wp-spell` — Spell Checker

Assembles the five-stage spell pipeline to detect misspelled words.

```bash
wp-spell [OPTIONS] [FILE]

Options:
  -d FILE     Use an alternate dictionary file
  -a WORD     Add WORD to the dictionary, then exit
  --count     Print only the count of misspelled words
  --no-commit Force read-only mode
```

The spell pipeline consists of:
1. `wp-spell-words` — Extract words from text
2. `wp-spell-lower` — Normalize to lowercase
3. `sort` — Sort words alphabetically
4. `wp-spell-unique` — Remove duplicates
5. `wp-spell-mismatch` — Compare against dictionary

## Dictionary Maintenance

The dictionary is stored in `lib/dictionary.txt` as a sorted list of valid words, one per line.

### Adding Words

Add a word using `wp-spell`:

```bash
wp-spell -a newword
```

Or manually append and re-sort:

```bash
echo "newword" >> lib/dictionary.txt
sort -o lib/dictionary.txt lib/dictionary.txt
```

### Removing Words

```bash
grep -v "^oldword$" lib/dictionary.txt > /tmp/dict.tmp
mv /tmp/dict.tmp lib/dictionary.txt
```

### Re-sorting

Always keep the dictionary sorted for efficient lookups:

```bash
sort -o lib/dictionary.txt lib/dictionary.txt
```

## Running Tests

### Run All Tests

```bash
make test
```

Or manually:

```bash
# All unit tests
for t in tests/test-*.sh; do bash "$t"; done

# Integration test
bash tests/test-spell-integration.sh

# End-to-end test
bash tests/test-e2e.sh
```

### Test Files

| File | Description |
|------|-------------|
| `tests/test-spell-words.sh` | Unit tests for word extraction |
| `tests/test-spell-lower.sh` | Unit tests for lowercase normalization |
| `tests/test-spell-unique.sh` | Unit tests for duplicate removal |
| `tests/test-spell-mismatch.sh` | Unit tests for dictionary comparison |
| `tests/test-stats.sh` | Unit tests for statistics |
| `tests/test-undo.sh` | Unit tests for undo functionality |
| `tests/test-spell-integration.sh` | Integration tests for spell pipeline |
| `tests/test-e2e.sh` | End-to-end session workflow tests |

## Installation

```bash
make install
```

This installs all tools to `~/.local/bin` (or `$INSTALL_DIR` if specified).

```bash
make install INSTALL_DIR=/usr/local/bin
```

## Session Structure

```
session/
├── current      → history/0002.txt   # Symlink to active snapshot
├── meta         # Session metadata (seq, source file)
└── history/
    ├── 0001.txt  # Initial snapshot
    ├── 0002.txt  # First edit
    └── ...
```

## License

MIT
