#!/bin/bash
# Fix default audio sink - smart device selection
# This script is called by i3 on startup and can be run manually
#
# Priority order:
# 1. USB Composite Device (home setup)
# 2. First USB audio device found
# 3. Built-in Audio (fallback)

log_file="/tmp/audio-fix.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$log_file"
    echo "$1"
}

# Try to find and set the preferred audio sink
find_and_set_sink() {
    # Get all available sinks
    local sinks=$(wpctl status | awk '
        /.*Sinks:/ { in_sinks = 1; next }
        /.*Sources:/ { in_sinks = 0 }
        in_sinks && /[0-9]+\./ {
            match($0, ".*[ ]([0-9]+)\\. (.+)", arr)
            if (arr[1] && arr[2]) {
                print arr[1] "|" arr[2]
            }
        }
    ')

    if [[ -z "$sinks" ]]; then
        log "ERROR: No audio sinks found"
        return 1
    fi

    # Priority 1: USB Composite Device (home setup)
    local sink_id=$(echo "$sinks" | grep "USB Composite Device" | head -1 | cut -d'|' -f1)
    if [[ -n "$sink_id" ]]; then
        wpctl set-default "$sink_id"
        local sink_name=$(echo "$sinks" | grep "^$sink_id|" | cut -d'|' -f2)
        log "✓ Set default sink to: $sink_name (ID: $sink_id)"
        return 0
    fi

    # Priority 2: Any USB audio device
    sink_id=$(echo "$sinks" | grep -i "usb" | grep -v "Built-in" | head -1 | cut -d'|' -f1)
    if [[ -n "$sink_id" ]]; then
        wpctl set-default "$sink_id"
        local sink_name=$(echo "$sinks" | grep "^$sink_id|" | cut -d'|' -f2)
        log "✓ Set default sink to USB device: $sink_name (ID: $sink_id)"
        return 0
    fi

    # Priority 3: Built-in Audio (fallback)
    sink_id=$(echo "$sinks" | grep "Built-in" | head -1 | cut -d'|' -f1)
    if [[ -n "$sink_id" ]]; then
        wpctl set-default "$sink_id"
        local sink_name=$(echo "$sinks" | grep "^$sink_id|" | cut -d'|' -f2)
        log "⚠ Fallback to built-in: $sink_name (ID: $sink_id)"
        return 0
    fi

    # Last resort: first available sink
    sink_id=$(echo "$sinks" | head -1 | cut -d'|' -f1)
    if [[ -n "$sink_id" ]]; then
        wpctl set-default "$sink_id"
        local sink_name=$(echo "$sinks" | grep "^$sink_id|" | cut -d'|' -f2)
        log "⚠ Using first available: $sink_name (ID: $sink_id)"
        return 0
    fi

    log "ERROR: Could not set any audio sink"
    return 1
}

# Show current status if verbose flag
if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
    log "=== Available Audio Sinks ==="
    wpctl status | grep -A 20 "Sinks:" | grep -E "^\s+\*?\s+[0-9]+"
    log ""
fi

# Set the sink
find_and_set_sink

# Show what was set
if [[ "$1" == "-v" || "$1" == "--se" ]]; then
    log ""
    log "=== Current Default Sink ==="
    wpctl status | grep -A 20 "Sinks:" | grep "^\s+\*"
fi
