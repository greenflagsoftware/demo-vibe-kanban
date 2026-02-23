#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/../wp/tests/harness.sh"

SCRIPT="$SCRIPT_DIR/../bin/spell/wp-spell-unique"

# Test 1: cat cat dog -> cat dog
input=$'cat\ncat\ndog'
expected=$'cat\ndog'
actual=$(echo "$input" | "$SCRIPT")
assert_eq "Test 1: remove consecutive duplicates" "$expected" "$actual"

# Test 2: the the the -> the
input=$'the\nthe\nthe'
expected='the'
actual=$(echo "$input" | "$SCRIPT")
assert_eq "Test 2: triple duplicate" "$expected" "$actual"

# Test 3: no duplicates - apple berry cat
input=$'apple\nberry\ncat'
expected=$'apple\nberry\ncat'
actual=$(echo "$input" | "$SCRIPT")
assert_eq "Test 3: no duplicates unchanged" "$expected" "$actual"

# Test 4: single word repeated 100 times
input=$(printf 'word\n%.0s' {1..100})
expected='word'
actual=$(echo "$input" | "$SCRIPT")
assert_eq "Test 4: 100 duplicates reduced to one" "$expected" "$actual"

# Test 5: empty input
input=''
expected=''
actual=$(echo -n "$input" | "$SCRIPT" || true)
assert_eq "Test 5: empty input" "$expected" "$actual"

report
