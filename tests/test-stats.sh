#!/usr/bin/env bash
#
# tests/test-stats.sh - Test cases for wp-stats
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/harness.sh"

WP_STATS="$SCRIPT_DIR/../bin/wp-stats"
FIXTURE="$SCRIPT_DIR/fixtures/sample.txt"

# Test 1: Known input, -w flag (word count = 50)
result=$("$WP_STATS" -w "$FIXTURE")
assert_eq "Word count with -w flag" "50" "$result"

# Test 2: Known input, -l flag (line count = 5)
result=$("$WP_STATS" -l "$FIXTURE")
assert_eq "Line count with -l flag" "5" "$result"

# Test 3: Known input, -s flag (sentence count = 5)
result=$("$WP_STATS" -s "$FIXTURE")
assert_eq "Sentence count with -s flag" "5" "$result"

# Test 4: Known input, -p flag (paragraph count = 3)
result=$("$WP_STATS" -p "$FIXTURE")
assert_eq "Paragraph count with -p flag" "3" "$result"

# Test 5: --freq 3 on known input (top 3 non-stopwords)
result=$("$WP_STATS" --freq 3 "$FIXTURE")
# All words appear once, so just check format and that we get 3 lines
line_count=$(echo "$result" | wc -l | tr -d ' ')
assert_eq "Freq 3 returns 3 lines" "3" "$line_count"

# Test 6: Empty input (outputs zeros, exits 0)
result=$(echo -n "" | "$WP_STATS" -w)
exit_code=$?
assert_eq "Empty input word count" "0" "$result"
assert_exit_code "Empty input exits 0" "0" "$exit_code"

# Test 7: Single word, no newline (word count = 1)
result=$(echo -n "hello" | "$WP_STATS" -w)
assert_eq "Single word no newline" "1" "$result"

# Run report
report
