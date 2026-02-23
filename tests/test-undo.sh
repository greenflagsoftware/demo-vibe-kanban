#!/usr/bin/env bash
# test-undo.sh - Tests for wp-undo

set -euo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/../wp/tests/harness.sh"
source "$SCRIPT_DIR/../wp/lib/wp-common.sh"

# Path to wp-undo
WP_UNDO="$(dirname "$SCRIPT_DIR")/wp/bin/wp-undo"

# Create a temporary session with known snapshots
setup_session() {
    export WP_SESSION
    WP_SESSION=$(mktemp -d)
    mkdir -p "$WP_SESSION/history"
    
    # Create snapshot files with known content
    echo -e "apple banana cherry" > "$WP_SESSION/history/0001.txt"
    echo -e "apple banana cherry dog" > "$WP_SESSION/history/0002.txt"
    echo -e "apple banana cherry dog elephant" > "$WP_SESSION/history/0003.txt"
    echo -e "apple banana cherry dog elephant fox" > "$WP_SESSION/history/0004.txt"
    
    # Set current to snapshot 4
    ln -sfn "$WP_SESSION/history/0004.txt" "$WP_SESSION/current"
    
    # Set meta
    echo -e "seq=0004\nsource=test" > "$WP_SESSION/meta"
}

# Cleanup temporary session
cleanup_session() {
    if [[ -n "${WP_SESSION:-}" ]]; then
        rm -rf "$WP_SESSION"
    fi
}

# Test 1: Step back once from snapshot 3
test_step_back_once() {
    local name="Step back once from snapshot 3"
    setup_session
    
    # First set current to snapshot 3
    ln -sfn "$WP_SESSION/history/0003.txt" "$WP_SESSION/current"
    echo -e "seq=0003\nsource=test" > "$WP_SESSION/meta"
    
    # Run wp-undo
    "$WP_UNDO"
    
    local seq
    seq=$(wp_seq)
    
    cleanup_session
    
    assert_eq "$name" "2" "$seq"
}

# Test 2: Step back -n 2 from snapshot 4
test_step_back_n() {
    local name="Step back -n 2 from snapshot 4"
    setup_session
    
    # Run wp-undo -n 2
    "$WP_UNDO" -n 2
    
    local seq
    seq=$(wp_seq)
    
    cleanup_session
    
    assert_eq "$name" "2" "$seq"
}

# Test 3: Step back from snapshot 1 (should fail)
test_step_back_at_oldest() {
    local name="Step back from snapshot 1 (error expected)"
    setup_session
    
    # Set current to snapshot 1
    ln -sfn "$WP_SESSION/history/0001.txt" "$WP_SESSION/current"
    echo -e "seq=0001\nsource=test" > "$WP_SESSION/meta"
    
    local seq_before
    seq_before=$(wp_seq)
    local exit_code=0
    "$WP_UNDO" 2>/dev/null || exit_code=$?
    
    local seq_after
    seq_after=$(wp_seq)
    
    cleanup_session
    
    assert_eq "$name" "1" "$exit_code"
}

# Test 4: --list shows all snapshots
test_list() {
    local name="--list shows all snapshots"
    setup_session
    
    local output
    output=$("$WP_UNDO" --list)
    
    cleanup_session
    
    # Check that output contains all sequence numbers and word counts
    local has_all=true
    [[ "$output" =~ \[0001\] ]] || has_all=false
    [[ "$output" =~ \[0002\] ]] || has_all=false
    [[ "$output" =~ \[0003\] ]] || has_all=false
    [[ "$output" =~ \[0004\] ]] || has_all=false
    [[ "$output" =~ "words" ]] || has_all=false
    [[ "$output" =~ "current" ]] || has_all=false
    
    assert_eq "$name" "true" "$has_all"
}

# Test 5: --jump 2 from snapshot 4
test_jump() {
    local name="--jump 2 from snapshot 4"
    setup_session
    
    "$WP_UNDO" --jump 2
    
    local seq
    seq=$(wp_seq)
    
    cleanup_session
    
    assert_eq "$name" "2" "$seq"
}

# Test 6: --jump to non-existent snapshot
test_jump_nonexistent() {
    local name="--jump to non-existent snapshot"
    setup_session
    
    local seq_before
    seq_before=$(wp_seq)
    local exit_code=0
    "$WP_UNDO" --jump 99 2>/dev/null || exit_code=$?
    
    local seq_after
    seq_after=$(wp_seq)
    
    cleanup_session
    
    assert_eq "$name" "1" "$exit_code"
}

# Test 7: --diff 1 between two known snapshots
test_diff() {
    local name="--diff 1 between two known snapshots"
    setup_session
    
    local output
    output=$("$WP_UNDO" --diff 1 2>&1) || true
    
    cleanup_session
    
    # Check that output contains diff markers (added/removed lines)
    local has_diff=false
    [[ "$output" =~ "fox" ]] && has_diff=true
    
    assert_eq "$name" "true" "$has_diff"
}

# Run all tests
test_step_back_once
test_step_back_n
test_step_back_at_oldest
test_list
test_jump
test_jump_nonexistent
test_diff

report
