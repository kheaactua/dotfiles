#!/bin/bash
# Polybar theme switcher that works with postswitch.py
# Usage: polybar-theme [theme-name]
# Available themes: blocks, colorblocks, cuts, docky, forest, grayblocks, hack, material, shades, shapes

POLYBAR_DIR="$HOME/.config/polybar"
THEME_LINK="$POLYBAR_DIR/current-theme"

# If no argument, show current theme and available options
if [[ -z "$1" ]]; then
    echo "Usage: $(basename $0) <theme-name>"
    echo ""
    if [[ -L "$THEME_LINK" ]]; then
        CURRENT=$(readlink "$THEME_LINK" | xargs basename | sed 's/config.ini//')
        echo "Current theme: $CURRENT"
    else
        echo "No theme currently selected"
    fi
    echo ""
    echo "Available themes:"
    ls -1 "$POLYBAR_DIR" | grep -v "\.sh$\|\.ini$\|\.md$\|^current-theme$" | sed 's/^/  - /'
    exit 0
fi

THEME="$1"

# Validate theme exists
if [[ ! -d "$POLYBAR_DIR/$THEME" ]]; then
    echo "Error: Theme '$THEME' not found"
    echo "Available themes:"
    ls -1 "$POLYBAR_DIR" | grep -v "\.sh$\|\.ini$\|\.md$\|^current-theme$" | sed 's/^/  - /'
    exit 1
fi

# Create/update symlink to current theme
ln -sf "$POLYBAR_DIR/$THEME/config.ini" "$THEME_LINK"
echo "✓ Theme symlink updated: $THEME"

# Relaunch polybar using postswitch.py to maintain monitor configuration
echo "✓ Relaunching polybar..."
python3 ~/.config/autorandr/postswitch.py

echo "✓ Done! Theme switched to: $THEME"
