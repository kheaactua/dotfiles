# TODO how to rename without restarting https://faq.i3wm.org/question/1774/rename-workspace-with-i3-input-using-numbers-and-text.1.html

# Assign windows to a Workspace
assign [class="qBittorrent"] $ws10

# Put Workspaces on specific monitors
# DVI-D-2 = Wide Dell
# DVI-D-1 = Big Shimian
# HDMI-1 = ASUS
# Position these with arandr, save the file, then paste the contents here:
exec --no-startup-id ~/.screenlayout/host.sh
workspace $ws1 output DisplayPort-0
workspace $ws2 output DisplayPort-1
workspace $ws3 output DisplayPort-2
