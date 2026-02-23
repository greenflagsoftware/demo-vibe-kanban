#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/harness.sh"

SPELL_WORDS="$SCRIPT_DIR/../bin/spell/wp-spell-words"

# Test 1: Hello, world!
result=$(echo "Hello, world!" | "$SPELL_WORDS")
expected=$'Hello\nworld'
assert_eq "Hello, world!" "$expected" "$result"

# Test 2: time-sharing
result=$(echo "time-sharing" | "$SPELL_WORDS")
expected=$'time\nsharing'
assert_eq "time-sharing" "$expected" "$result"

# Test 3: Chapter 12 (numbers discarded)
result=$(echo "Chapter 12" | "$SPELL_WORDS")
expected="Chapter"
assert_eq "Chapter 12" "$expected" "$result"

# Test 4: empty string
result=$(echo -n "" | "$SPELL_WORDS" || true)
expected=""
assert_eq "empty string" "$expected" "$result"

# Test 5: won't stop (contraction split)
result=$(echo "won't stop" | "$SPELL_WORDS")
expected=$'won\nt\nstop'
assert_eq "won't stop" "$expected" "$result"

# Test 6: ... (only punctuation)
result=$(echo "..." | "$SPELL_WORDS" || true)
expected=""
assert_eq "... (only punctuation)" "$expected" "$result"

report
