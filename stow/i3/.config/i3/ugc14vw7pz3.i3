# Set mod key to "opt|start"
set $mod Mod4

# Name the workspaces
set $ws1  "1: Docs"
set $ws2  "2: Main"
set $ws3  "3: Coms"
set $ws4  "4"
set $ws5  "5"
set $ws6  "6"
set $ws7  "7"
set $ws8  "8"
set $ws9  "9: VPN"
set $ws10 "10"
set $ws11 "T"
set $ws12 "M"

# Specify the displays
set $monitor_left "DP-6"
set $monitor_center "DP-2"
set $monitor_right "DP-0"

include ~/.config/i3/0-common-base.i3
include ~/.config/i3/1-host-ugc14vw7pz3.i3
include ~/.config/i3/2-workspaces.i3
include ~/.config/i3/4-*.i3
include ~/.config/i3/5-*.i3
