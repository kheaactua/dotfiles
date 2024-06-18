set $mod Mod4

# Name the workspaces
set $ws1   "1"
set $ws2   "2: Main"
set $ws3   "3: Social"
set $ws4   "4"
set $ws5   "5"
set $ws6   "6"
set $ws7   "7"
set $ws8   "8"
set $ws9   "9"
set $ws10 "10: Media"
set $ws11 "T"
set $ws12 "M"

# Specify the displays
set $monitor_left "DisplayPort-0"
set $monitor_center "DisplayPort-1"
set $monitor_right "DisplayPort-2"

include ~/.config/i3/0-common-base.i3
include ~/.config/i3/1-windows.i3
include ~/.config/i3/1-host-khea.i3
include ~/.config/i3/2-workspaces.i3
include ~/.config/i3/4-*.i3
include ~/.config/i3/5-*.i3
