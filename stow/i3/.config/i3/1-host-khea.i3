# TODO how to rename without restarting https://faq.i3wm.org/question/1774/rename-workspace-with-i3-input-using-numbers-and-text.1.html

# Assign windows to a Workspace
assign [class="qBittorrent"] $ws10
assign [class="torguard"] $ws10

# starting some apps in floating mode
for_window [title="^TorGuard$"] floating enable, border normal 0

# Relay on autorandr's postswitch to position the workspaces
