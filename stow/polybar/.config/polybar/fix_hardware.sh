#!/bin/bash

# Improved Polybar Hardware Auto-Fix Script

set -e

POLYBAR_DIR="$HOME/.config/polybar"

echo "=== Polybar Hardware Detection ==="
echo

# Detect WiFi interface
WIFI_INTERFACE=$(ip link show | grep -E "wl[a-z0-9]+" | awk '{print $2}' | sed 's/:$//' | head -1)
echo "WiFi Interface: ${WIFI_INTERFACE:-NOT FOUND}"

# Detect Ethernet interface  
ETH_INTERFACE=$(ip link show | grep -E "en[a-z0-9]+" | grep -v "veth" | awk '{print $2}' | sed 's/:$//' | head -1)
echo "Ethernet Interface: ${ETH_INTERFACE:-NOT FOUND}"

# Detect backlight
BACKLIGHT=$(ls /sys/class/backlight/ 2>/dev/null | head -1)
echo "Backlight: ${BACKLIGHT:-NOT FOUND}"

# Detect battery
BATTERY=$(ls /sys/class/power_supply/ 2>/dev/null | grep "BAT" | head -1)
echo "Battery: ${BATTERY:-NOT FOUND}"

# Detect AC adapter
ADAPTER=$(ls /sys/class/power_supply/ 2>/dev/null | grep -E "^AC|^ADP" | head -1)
echo "AC Adapter: ${ADAPTER:-NOT FOUND}"

# Detect temperature sensor
TEMP_SENSOR=$(find /sys/devices -name "temp1_input" 2>/dev/null | grep -v "virtual" | head -1)
echo "Temperature Sensor: ${TEMP_SENSOR:-NOT FOUND}"

echo
echo "=== Applying Fixes ==="
echo

# Function to fix a modules.ini file
fix_modules_file() {
    local file=$1
    echo "Fixing: $file"
    
    if [[ ! -f "$file" ]]; then
        echo "  Skipping (file not found)"
        return
    fi
    
    # Create temp file
    local tmpfile=$(mktemp)
    
    # Process file line by line
    awk -v wifi="$WIFI_INTERFACE" \
        -v eth="$ETH_INTERFACE" \
        -v backlight="$BACKLIGHT" \
        -v battery="$BATTERY" \
        -v adapter="$ADAPTER" \
        -v temp="$TEMP_SENSOR" '
    BEGIN { in_mpd = 0; in_backlight = 0; seen_card = 0 }
    
    # Detect MPD module start
    /^\[module\/mpd\]/ { 
        in_mpd = 1
        print ";[module/mpd]  # Disabled - uncomment if using Music Player Daemon"
        next
    }
    
    # Detect backlight module
    /^\[module\/backlight\]/ {
        in_backlight = 1
        seen_card = 0
    }
    
    # End of module detection
    /^\[module\// && !/^\[module\/mpd\]/ && !/^\[module\/backlight\]/ {
        in_mpd = 0
        in_backlight = 0
        seen_card = 0
    }
    
    # Comment out MPD module content
    in_mpd && /^[^;]/ && !/^\[/ {
        print ";" $0
        next
    }
    
    # Fix WiFi interface
    /^interface = wlan[0-9]/ && wifi != "" {
        print "interface = " wifi
        next
    }
    
    # Fix Ethernet interface
    /^interface = (eth[0-9]|enp[a-z0-9]+)/ && eth != "" {
        print "interface = " eth
        next
    }
    
    # Fix backlight - handle duplicates
    /^card = (amdgpu_bl|intel_backlight)/ && in_backlight {
        if (seen_card == 0 && backlight != "") {
            print "card = " backlight
            seen_card = 1
        }
        next
    }
    
    # Handle commented backlight cards
    /^;card = intel_backlight/ && backlight != "" && seen_card == 0 {
        print "card = " backlight
        seen_card = 1
        next
    }
    
    # Fix battery
    /^battery = BAT[0-9]/ && battery != "" {
        print "battery = " battery
        next
    }
    
    # Fix AC adapter
    /^adapter = (ACAD|AC[0-9])/ && adapter != "" {
        print "adapter = " adapter
        next
    }
    
    # Fix temperature hwmon-path
    /^hwmon-path = \/sys\/devices/ && temp != "" {
        print "hwmon-path = " temp
        next
    }
    
    # Print all other lines unchanged
    { print }
    ' "$file" > "$tmpfile"
    
    # Replace original with fixed version
    mv "$tmpfile" "$file"
    
    echo "  ✓ Fixed hardware paths"
}

# Fix all theme modules.ini files
for theme_dir in "$POLYBAR_DIR"/*/; do
    if [[ -d "$theme_dir" ]]; then
        modules_file="${theme_dir}modules.ini"
        
        if [[ -f "$modules_file" ]]; then
            fix_modules_file "$modules_file"
        fi
    fi
done

# Also fix the main config.ini if it exists
if [[ -f "$POLYBAR_DIR/config.ini" ]]; then
    fix_modules_file "$POLYBAR_DIR/config.ini"
fi

echo
echo "=== Done! ==="
echo
echo "Summary:"
echo "  - WiFi → $WIFI_INTERFACE"
echo "  - Ethernet → $ETH_INTERFACE"
echo "  - Backlight → $BACKLIGHT"
echo "  - Battery → $BATTERY"
echo "  - AC Adapter → $ADAPTER"
echo "  - Temperature → $TEMP_SENSOR"
echo "  - MPD module disabled"
echo
echo "Test with: ~/.config/polybar/launch.sh --blocks"
