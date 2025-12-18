#!/usr/bin/env bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Configuration: Choose which monitors to show Polybar on
# Options:
#   "all" - Show on all connected monitors
#   "primary" - Show only on primary monitor
#   "DP-1-2" - Show only on specific monitor (use xrandr to find names)
#   "DP-1-1 DP-1-2" - Show on multiple specific monitors (space-separated)
POLYBAR_MONITORS="DP-1-2"

# Launch Polybar
if type "xrandr" > /dev/null; then
  if [ "$POLYBAR_MONITORS" = "all" ]; then
    # Launch on all connected monitors
    for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
      MONITOR=$m polybar --reload main 2>&1 | tee -a /tmp/polybar_$m.log & disown
    done
  elif [ "$POLYBAR_MONITORS" = "primary" ]; then
    # Launch only on primary monitor
    PRIMARY=$(xrandr --query | grep " connected primary" | cut -d" " -f1)
    MONITOR=$PRIMARY polybar --reload main 2>&1 | tee -a /tmp/polybar_$PRIMARY.log & disown
  else
    # Launch on specific monitors
    for m in $POLYBAR_MONITORS; do
      # Check if monitor is connected
      if xrandr --query | grep "^$m connected" > /dev/null; then
        MONITOR=$m polybar --reload main 2>&1 | tee -a /tmp/polybar_$m.log & disown
      fi
    done
  fi
else
  polybar --reload main 2>&1 | tee -a /tmp/polybar_main.log & disown
fi

echo "Polybar launched..."
