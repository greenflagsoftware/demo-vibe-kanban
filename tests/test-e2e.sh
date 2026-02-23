#!/usr/bin/env bash
#
# test-e2e.sh - End-to-end session integration test
# Simulates a full editing session using all tools together
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source test harness
source "$SCRIPT_DIR/harness.sh"

# Paths
WP="$PROJECT_ROOT/bin/wp"
WP_SEARCH="$PROJECT_ROOT/bin/wp-search"
WP_UNDO="$PROJECT_ROOT/bin/wp-undo"
WP_SPELL="$PROJECT_ROOT/bin/spell/wp-spell"
WP_STATS="$PROJECT_ROOT/bin/wp-stats"

# Source common library for wp_seq
source "$PROJECT_ROOT/lib/wp-common.sh"

# Test document
TEST_DOC="/tmp/test-e2e-doc.txt"
TEST_SESSION="/tmp/test-e2e-session"

# Cleanup on exit
cleanup() {
    rm -f "$TEST_DOC"
    rm -rf "$TEST_SESSION"
}
trap cleanup EXIT

# Setup
echo "The kittne sat on the matt. It was a grate day." > "$TEST_DOC"

# Initialize session with custom session directory
export WP_SESSION="$TEST_SESSION"
"$WP" init "$TEST_DOC"

# Spell check - kittne should be flagged
ERRORS=$("$WP" pipe | "$WP_SPELL")
assert_contains "e2e: kittne flagged" "$ERRORS" "kittne"

# Fix a word using wp run wp-search
"$WP" run wp-search "kittne" "kitten"

# Sequence should be incremented
assert_eq "e2e: seq incremented" "2" "$(wp_seq)"

# Verify fix - kittne should be gone
ERRORS_AFTER=$("$WP" pipe | "$WP_SPELL")
assert_not_contains "e2e: kittne resolved" "$ERRORS_AFTER" "kittne"

# Stats - word count
WORDS=$("$WP" pipe | "$WP_STATS" -w)
assert_eq "e2e: word count" "11" "$WORDS"

# Undo
"$WP_UNDO"
assert_eq "e2e: undo restores seq" "1" "$(wp_seq)"

# Verify original error is back after undo
ERRORS_UNDONE=$("$WP" pipe | "$WP_SPELL")
assert_contains "e2e: error back after undo" "$ERRORS_UNDONE" "kittne"

# Cleanup session
rm -rf "$TEST_SESSION"

echo ""
report
