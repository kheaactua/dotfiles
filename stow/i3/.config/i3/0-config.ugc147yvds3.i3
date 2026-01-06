# Set mod key to "opt|start"
set $mod Mod4

# Name the workspaces
# Keeping them mostly numeric because otherwise "move workspace" is a PITA
set $ws1  "1"
set $ws2  "2: Main"
set $ws3  "3"
set $ws4  "4: Social"
set $ws5  "5"
set $ws6  "6"
set $ws7  "7"
set $ws8  "8"
set $ws9  "9: VPN"
set $ws10 "10"
set $ws11 "T"
set $ws12 "M: Music"

include ~/.config/i3/1-common-base.i3
include ~/.config/i3/2-windows.i3
include ~/.config/i3/2-host-ugc147yvds3.i3
include ~/.config/i3/3-workspaces.i3
include ~/.config/i3/5-*.i3
include ~/.config/i3/6-*.i3
