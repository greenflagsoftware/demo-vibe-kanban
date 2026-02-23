#!/usr/bin/env bash
# Note: If /usr/share/dict/words is not available, install it with:
#   sudo apt-get install wamerican
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/harness.sh"

SPELL_MISMATCH="${SCRIPT_DIR}/../bin/spell/wp-spell-mismatch"
TEST_DICT="${SCRIPT_DIR}/fixtures/test-dict.txt"

# Test 1: All words in test dictionary - no output, exit 0
test_all_known_words() {
    local output
    output=$(echo -e "cat\ndog\nfox" | "$SPELL_MISMATCH" -d "$TEST_DICT")
    assert_eq "All words in test dictionary - no output" "" "$output"
}

# Test 2: One misspelled word `kittne` - outputs `kittne`
test_one_misspelled_word() {
    local output
    output=$(echo "kittne" | "$SPELL_MISMATCH" -d "$TEST_DICT")
    assert_eq "One misspelled word - outputs kittne" "kittne" "$output"
}

# Test 3: Two misspelled words - both output, one per line
test_two_misspelled_words() {
    local output
    # Input must be sorted for comm to work correctly
    output=$(echo -e "dogg\nkittne" | "$SPELL_MISMATCH" -d "$TEST_DICT")
    local expected="dogg
kittne"
    assert_eq "Two misspelled words - both output" "$expected" "$output"
}

# Test 4: Empty input - no output, exit 0
test_empty_input() {
    local output
    output=$(echo -n "" | "$SPELL_MISMATCH" -d "$TEST_DICT")
    assert_eq "Empty input - no output" "" "$output"
}

# Test 5: -a flag adds word to a temp copy of the dictionary
test_add_word_flag() {
    local temp_dict
    temp_dict=$(mktemp)
    cp "$TEST_DICT" "$temp_dict"
    
    # Add a new word to the temp dictionary
    "$SPELL_MISMATCH" -d "$temp_dict" -a "newword"
    
    # Now check that newword is no longer flagged
    local output
    output=$(echo "newword" | "$SPELL_MISMATCH" -d "$temp_dict")
    
    rm -f "$temp_dict"
    
    assert_eq "-a flag adds word to dictionary" "" "$output"
}

# Test 6: -d flag uses alternate dictionary
test_alternate_dictionary() {
    # Create a minimal alternate dictionary
    local alt_dict
    alt_dict=$(mktemp)
    echo "only" > "$alt_dict"
    echo "words" >> "$alt_dict"
    echo "here" >> "$alt_dict"
    sort -o "$alt_dict" "$alt_dict"
    
    # Test that "cat" is flagged as misspelled (not in alt_dict)
    local output
    output=$(echo "cat" | "$SPELL_MISMATCH" -d "$alt_dict")
    
    rm -f "$alt_dict"
    
    assert_eq "-d flag uses alternate dictionary" "cat" "$output"
}

# Run all tests
test_all_known_words
test_one_misspelled_word
test_two_misspelled_words
test_empty_input
test_add_word_flag
test_alternate_dictionary

report
