#!/bin/bash
# Toggle polybar position between top and bottom for all themes
# Usage: polybar-position [top|bottom|toggle]

POLYBAR_DIR="$HOME/.config/polybar"
ACTION="${1:-toggle}"

get_current_position() {
    # Check the first theme to see current position
    local pos=$(grep "^bottom = " "$POLYBAR_DIR/blocks/config.ini" | head -1 | awk '{print $3}')
    echo "$pos"
}

set_position() {
    local new_position=$1
    
    if [[ "$new_position" != "true" && "$new_position" != "false" ]]; then
        echo "Error: Position must be 'true' (bottom) or 'false' (top)"
        return 1
    fi
    
    echo "Setting polybar position: $([ "$new_position" = "true" ] && echo "BOTTOM" || echo "TOP")"
    
    # Update all theme configs
    for theme in blocks colorblocks cuts docky forest grayblocks hack material shades shapes; do
        config="$POLYBAR_DIR/$theme/config.ini"
        if [[ -f "$config" ]]; then
            # Replace all "bottom = true/false" lines
            sed -i "s/^bottom = .*/bottom = $new_position/" "$config"
            echo "  ✓ Updated $theme"
        fi
    done
    
    # Also update main config.ini if it exists
    if [[ -f "$POLYBAR_DIR/config.ini" ]]; then
        sed -i "s/^bottom = .*/bottom = $new_position/" "$POLYBAR_DIR/config.ini"
        echo "  ✓ Updated config.ini"
    fi
    
    echo ""
    echo "Reloading polybar..."
    python3 ~/.config/autorandr/postswitch.py
    
    echo "✓ Done! Polybar moved to $([ "$new_position" = "true" ] && echo "BOTTOM" || echo "TOP")"
}

case "$ACTION" in
    top)
        set_position "false"
        ;;
    bottom)
        set_position "true"
        ;;
    toggle)
        current=$(get_current_position)
        if [[ "$current" == "true" ]]; then
            set_position "false"
        else
            set_position "true"
        fi
        ;;
    *)
        echo "Usage: $(basename $0) [top|bottom|toggle]"
        echo ""
        echo "Current position: $([ "$(get_current_position)" = "true" ] && echo "BOTTOM" || echo "TOP")"
        exit 1
        ;;
esac
