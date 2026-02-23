#!/usr/bin/env bash
#
# test-spell-integration.sh - Integration tests for wp-spell pipeline
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source test harness
source "$SCRIPT_DIR/harness.sh"

# Paths
WP_SPELL="$PROJECT_ROOT/bin/spell/wp-spell"
DICT_FILE="$PROJECT_ROOT/lib/dictionary.txt"

# Backup original dictionary
DICT_BACKUP=$(mktemp)
cp "$DICT_FILE" "$DICT_BACKUP"

# Add common words to dictionary for tests
echo "bird" >> "$DICT_FILE"
echo "here" >> "$DICT_FILE"
echo "is" >> "$DICT_FILE"
echo "mat" >> "$DICT_FILE"
echo "sat" >> "$DICT_FILE"
sort -o "$DICT_FILE" "$DICT_FILE"

# Cleanup on exit
cleanup() {
    cp "$DICT_BACKUP" "$DICT_FILE"
    rm -f "$DICT_BACKUP"
    rm -rf /tmp/test-spell-*
}
trap cleanup EXIT

# Test 1: Document with no misspellings (using only dictionary words)
test_no_misspellings() {
    local test_file="/tmp/test-spell-no-errors.txt"
    # All these words are in the dictionary
    echo "we are with you and they will be here is it so" > "$test_file"
    
    local result
    result=$("$WP_SPELL" "$test_file")
    
    assert_eq "spell: no misspellings - no output" "" "$result"
}

# Test 2: Document with 2 known misspellings
test_two_misspellings() {
    local test_file="/tmp/test-spell-two-errors.txt"
    echo "the kittne sat on the matt" > "$test_file"
    
    local result
    result=$("$WP_SPELL" "$test_file")
    
    assert_contains "spell: kittne flagged" "$result" "kittne"
    assert_contains "spell: matt flagged" "$result" "matt"
}

# Test 3: Misspelled word in mixed case
test_mixed_case() {
    local test_file="/tmp/test-spell-mixed-case.txt"
    echo "the KiTtNe sat on the MaTt" > "$test_file"
    
    local result
    result=$("$WP_SPELL" "$test_file")
    
    assert_contains "spell: mixed case kittne caught" "$result" "kittne"
    assert_contains "spell: mixed case matt caught" "$result" "matt"
}

# Test 4: Word added via -a, re-run
test_add_word() {
    local test_file="/tmp/test-spell-add-word.txt"
    local new_word="flibbernaught"
    echo "we saw the $new_word with you" > "$test_file"
    
    # First run - should flag the new word
    local result_before
    result_before=$("$WP_SPELL" "$test_file")
    assert_contains "spell: new word flagged before adding" "$result_before" "$new_word"
    
    # Add word to dictionary
    "$WP_SPELL" -d "$DICT_FILE" -a "$new_word"
    
    # Second run - should not flag the word
    local result_after
    result_after=$("$WP_SPELL" -d "$DICT_FILE" "$test_file")
    assert_not_contains "spell: new word not flagged after adding" "$result_after" "$new_word"
}

# Test 5: --count on document with 3 errors
test_count_option() {
    local test_file="/tmp/test-spell-count.txt"
    # Use only dictionary words except for the 3 misspellings
    echo "we will be the kittne and the matt with a grte bird" > "$test_file"
    
    local result
    result=$("$WP_SPELL" --count "$test_file")
    
    # kittne, matt, grte are misspelled (3 words)
    assert_eq "spell: count returns 3" "3" "$result"
}

# Test 6: Piped input with misspelling (works without a session)
test_piped_input() {
    local result
    result=$(echo "the kittne sat on the mat" | "$WP_SPELL" /dev/stdin)
    
    assert_contains "spell: piped input catches kittne" "$result" "kittne"
}

# Test 7: Full pipeline manual invocation
test_manual_pipeline() {
    local result
    result=$(echo "the kittne sat on the matt" \
        | "$PROJECT_ROOT/bin/spell/wp-spell-words" \
        | "$PROJECT_ROOT/bin/spell/wp-spell-lower" \
        | sort \
        | "$PROJECT_ROOT/bin/spell/wp-spell-unique" \
        | "$PROJECT_ROOT/bin/spell/wp-spell-mismatch" -d "$DICT_FILE")
    
    assert_contains "spell: manual pipeline catches kittne" "$result" "kittne"
    assert_contains "spell: manual pipeline catches matt" "$result" "matt"
    assert_not_contains "spell: manual pipeline excludes the" "$result" "the"
    assert_not_contains "spell: manual pipeline excludes on" "$result" "on"
}

# Run all tests
echo "=== wp-spell Integration Tests ==="
echo ""

test_no_misspellings
test_two_misspellings
test_mixed_case
test_add_word
test_count_option
test_piped_input
test_manual_pipeline

echo ""
report
