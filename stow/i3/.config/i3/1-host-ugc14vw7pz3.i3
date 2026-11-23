# Assign windows to a Workspace
assign [class="Stoken-gui"] $ws9
assign [class="Webex"] $ws3
assign [class="ZSTray"] $ws9

# starting some apps in floating mode
for_window [title="^Emulator$"] floating enable, border normal 0
for_window [title="^Android Emulator - <build>:.*"] floating enable, border normal 0

# Relay on autorandr's postswitch to position the workspaces
