#!/usr/bin/env bash
# wp-common.sh - Shared library for wp kanban tools
# All functions are prefixed with wp_

# ANSI color codes
readonly WP_COLOR_GREEN='\033[0;32m'
readonly WP_COLOR_YELLOW='\033[0;33m'
readonly WP_COLOR_RED='\033[0;31m'
readonly WP_COLOR_NC='\033[0m' # No Color

# wp_session_dir
# Prints the absolute path to the active session directory.
# Uses $WP_SESSION if set, otherwise defaults to ./session
# Does not create the directory.
wp_session_dir() {
    local dir="${WP_SESSION:-./session}"
    # Convert to absolute path
    if [[ -d "$dir" ]]; then
        (cd "$dir" && pwd)
    else
        # Directory might not exist yet, resolve relative to current dir
        local base_dir
        if [[ "$dir" = /* ]]; then
            echo "$dir"
        else
            echo "$(pwd)/$dir"
        fi
    fi
}

# wp_current
# Prints the resolved path of session/current (the active snapshot file).
# Exits with error code 1 and a message to stderr if session/current does not exist.
wp_current() {
    local session_dir
    session_dir="$(wp_session_dir)"
    local current="$session_dir/current"
    
    if [[ ! -e "$current" ]]; then
        wp_log ERR "No session exists. Run 'wp init <file>' first."
        exit 1
    fi
    
    # Resolve symlink to actual path
    readlink -f "$current"
}

# wp_commit
# Reads stdin, writes it to the next numbered snapshot in session/history/
# Snapshot filenames are zero-padded to 4 digits: 0001.txt, 0002.txt, etc.
# Updates session/current symlink to point to the new snapshot
# Increments the sequence counter stored in session/meta
wp_commit() {
    local session_dir
    session_dir="$(wp_session_dir)"
    local history_dir="$session_dir/history"
    local meta_file="$session_dir/meta"
    local current_link="$session_dir/current"
    
    # Ensure history directory exists
    mkdir -p "$history_dir"
    
    # Get current sequence number
    local seq=0
    if [[ -f "$meta_file" ]]; then
        seq=$(grep '^seq=' "$meta_file" | cut -d'=' -f2)
        seq=$((10#$seq)) # Remove leading zeros for arithmetic
    fi
    
    # Increment sequence
    seq=$((seq + 1))
    local padded_seq
    padded_seq=$(printf "%04d" "$seq")
    
    # Write snapshot
    local snapshot_file="$history_dir/${padded_seq}.txt"
    cat > "$snapshot_file"
    
    # Update current symlink
    ln -sf "$snapshot_file" "$current_link"
    
    # Update meta file
    local source_file
    if [[ -f "$meta_file" ]]; then
        source_file=$(grep '^source=' "$meta_file" | cut -d'=' -f2-)
    else
        source_file="unknown"
    fi
    
    {
        echo "seq=$padded_seq"
        echo "source=$source_file"
    } > "$meta_file"
}

# wp_seq
# Prints the current sequence number as a plain integer (e.g. 3)
wp_seq() {
    local session_dir
    session_dir="$(wp_session_dir)"
    local meta_file="$session_dir/meta"
    
    if [[ ! -f "$meta_file" ]]; then
        echo "0"
        return
    fi
    
    local seq
    seq=$(grep '^seq=' "$meta_file" | cut -d'=' -f2)
    echo "$((10#$seq))" # Remove leading zeros
}

# wp_log
# Usage: wp_log LEVEL "message"
# LEVEL is one of: INFO, WARN, ERR
# Writes to stderr only, never stdout
# Colorize output using ANSI codes: INFO=green, WARN=yellow, ERR=red
wp_log() {
    local level="$1"
    local message="$2"
    local color
    
    case "$level" in
        INFO)
            color="$WP_COLOR_GREEN"
            ;;
        WARN)
            color="$WP_COLOR_YELLOW"
            ;;
        ERR)
            color="$WP_COLOR_RED"
            ;;
        *)
            color="$WP_COLOR_NC"
            ;;
    esac
    
    echo -e "${color}[$level]${WP_COLOR_NC} $message" >&2
}

# wp_require_cmd
# Usage: wp_require_cmd cmd1 cmd2 ...
# For each argument, checks that the command exists via `command -v`
# If any are missing, prints an ERR log and exits with code 127
wp_require_cmd() {
    local missing=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        wp_log ERR "Missing required command(s): ${missing[*]}"
        exit 127
    fi
}

# wp_escape_sed
# Usage: wp_escape_sed "some/string.with[special]chars"
# Prints the string with /, ., [, ], *, ^, $, \ escaped for use in a sed expression
wp_escape_sed() {
    local input="$1"
    # Escape special sed characters: \ & / . [ ] * ^ $
    printf '%s' "$input" | sed -e 's/[]\/$*.^[]/\\&/g'
}
