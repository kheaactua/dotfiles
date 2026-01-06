# starting some apps in floating mode
for_window [class="org.gnome.Nautilus"] floating enable, border normal 0
for_window [class="matplotlib"] floating enable, border normal 0
for_window [title="^Event Tester$"] floating enable, border normal 0

# Float qBittorrent download dialog windows (but not the main window)
# Main window title is "qBittorrent v*", dialogs have torrent names
for_window [class="qBittorrent" title="^(?!qBittorrent v).*$"] floating enable, border normal 0
