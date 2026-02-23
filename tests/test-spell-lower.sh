#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/harness.sh"

SCRIPT="$SCRIPT_DIR/../bin/spell/wp-spell-lower"

# Test 1: Hello -> hello
result=$(echo "Hello" | "$SCRIPT")
assert_eq "Hello -> hello" "hello" "$result"

# Test 2: UNIX -> unix
result=$(echo "UNIX" | "$SCRIPT")
assert_eq "UNIX -> unix" "unix" "$result"

# Test 3: already -> already (no change)
result=$(echo "already" | "$SCRIPT")
assert_eq "already -> already" "already" "$result"

# Test 4: MiXeD -> mixed
result=$(echo "MiXeD" | "$SCRIPT")
assert_eq "MiXeD -> mixed" "mixed" "$result"

# Test 5: empty string -> no output, exit 0
result=$(echo -n "" | "$SCRIPT" || true)
exit_code=$?
assert_eq "empty string produces no output" "" "$result"
assert_exit_code "empty string exits 0" 0 "$exit_code"

# Test 6: three words on three lines
input=$'Hello\nUNIX\nMiXeD'
expected=$'hello\nunix\nmixed'
result=$(echo "$input" | "$SCRIPT")
assert_eq "three words on three lines" "$expected" "$result"

report
