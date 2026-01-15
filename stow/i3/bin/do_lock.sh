#!/bin/bash

# Hostname-aware i3lock-color with different themes for each machine
# Makes it easy to identify which computer is locked

HOSTNAME=$(hostname)

# Define color themes for each hostname
# i3lock-color uses RRGGBBAA format (with alpha channel)
case "$HOSTNAME" in
    UGC147YVDS3)
        # Work laptop - Blue theme
        BG_COLOR="1e3a8aff"           # Dark blue background
        RING_COLOR="3b82f6ff"         # Blue ring
        INSIDE_COLOR="1e40afff"       # Inside color
        TEXT_COLOR="ffffffff"         # White text
        VERIF_COLOR="10b981ff"        # Green when verifying
        WRONG_COLOR="ef4444ff"        # Red when wrong
        ;;
    UGC14VW7PZ3)
        # Work desktop - Green theme
        BG_COLOR="166534ff"           # Dark green background
        RING_COLOR="22c55eff"         # Green ring
        INSIDE_COLOR="15803dff"       # Inside color
        TEXT_COLOR="ffffffff"         # White text
        VERIF_COLOR="3b82f6ff"        # Blue when verifying
        WRONG_COLOR="ef4444ff"        # Red when wrong
        ;;
    khea)
        # Home - Purple theme
        BG_COLOR="581c87ff"           # Dark purple background
        RING_COLOR="a855f7ff"         # Purple ring
        INSIDE_COLOR="7c3aedff"       # Inside color
        TEXT_COLOR="ffffffff"         # White text
        VERIF_COLOR="10b981ff"        # Green when verifying
        WRONG_COLOR="ef4444ff"        # Red when wrong
        ;;
    WGC30047YVDS3)
        # Ford laptop - Orange theme
        BG_COLOR="9a3412ff"           # Dark orange background
        RING_COLOR="f97316ff"         # Orange ring
        INSIDE_COLOR="c2410cff"       # Inside color
        TEXT_COLOR="ffffffff"         # White text
        VERIF_COLOR="10b981ff"        # Green when verifying
        WRONG_COLOR="ef4444ff"        # Red when wrong
        ;;
    *)
        # Default - Red theme (for unknown hosts)
        BG_COLOR="991b1bff"           # Dark red background
        RING_COLOR="ef4444ff"         # Red ring
        INSIDE_COLOR="dc2626ff"       # Inside color
        TEXT_COLOR="ffffffff"         # White text
        VERIF_COLOR="10b981ff"        # Green when verifying
        WRONG_COLOR="fbbf24ff"        # Yellow when wrong
        ;;
esac

# Lock with hostname-specific theme
# i3lock-color has tons of customization options!
i3lock --nofork \
    --show-failed-attempts \
    --color="$BG_COLOR" \
    --insidever-color="$VERIF_COLOR" \
    --insidewrong-color="$WRONG_COLOR" \
    --inside-color="$INSIDE_COLOR" \
    --ringver-color="$VERIF_COLOR" \
    --ringwrong-color="$WRONG_COLOR" \
    --ring-color="$RING_COLOR" \
    --line-uses-ring \
    --keyhl-color="fbbf24ff" \
    --bshl-color="$WRONG_COLOR" \
    --separator-color="$RING_COLOR" \
    --verif-color="$TEXT_COLOR" \
    --wrong-color="$TEXT_COLOR" \
    --time-color="$TEXT_COLOR" \
    --date-color="$TEXT_COLOR" \
    --layout-color="$TEXT_COLOR" \
    --radius=120 \
    --ring-width=15 \
    --modif-size=10 \
    --modif-pos="x+w/2:y+h/2" \
    --time-str="%H:%M:%S" \
    --date-str="%A, %B %d" \
    --verif-text="Verifying..." \
    --wrong-text="Wrong!" \
    --noinput-text="No Input" \
    --lock-text="Locking..." \
    --lockfailed-text="Lock Failed" \
    --time-font="sans-serif" \
    --date-font="sans-serif" \
    --verif-font="sans-serif" \
    --wrong-font="sans-serif" \
    --clock \
    --indicator \
    --force-clock \
    --time-size=48 \
    --date-size=24 \
    --time-pos="x+w/2:y+h/2-200" \
    --date-pos="x+w/2:y+h/2-150" \
    --ind-pos="x+w/2:y+h/2"

# Re-enable numlock after unlocking (because i3lock turns it off)
numlockx on
