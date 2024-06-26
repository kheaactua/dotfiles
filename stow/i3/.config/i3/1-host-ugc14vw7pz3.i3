# Assign windows to a Workspace
assign [class="Stoken-gui"] $ws9
assign [class="Webex"] $ws3
assign [class="ZSTray"] $ws9

# starting some apps in floating mode
for_window [title="^Emulator$"] floating enable, border normal 0
for_window [title="^Android Emulator - <build>:.*"] floating enable, border normal 0

# Put Workspaces on specific monitors
# DP-0 = Older Dell
# DP-6 = Middle Dell
# DP-4 = Portrait Dell
# Position these with arandr, save the file, then paste the contents here:
exec --no-startup-id ~/.screenlayout/host.sh
workspace $ws1 output DP-6
workspace $ws2 output DP-4
workspace $ws3 output DP-0
