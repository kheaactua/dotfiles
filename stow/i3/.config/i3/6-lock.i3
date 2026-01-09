# Screen timeout and lock configuration
#
# NOTE: If running i3 on top of a GNOME session (via GDM), GNOME's power management
# can interfere with these settings. To disable GNOME's auto-lock:
#   gsettings set org.gnome.desktop.screensaver lock-enabled false
#   gsettings set org.gnome.desktop.session idle-delay 0
# These settings persist across reboots but aren't in dotfiles (stored in ~/.config/dconf/user)

# xss-lock grabs a logind suspend inhibit lock and will use i3lock-color to lock the
# screen before suspend. Use loginctl lock-session to lock your screen.
exec --no-startup-id xss-lock --transfer-sleep-lock -- ${HOME}/bin/do_lock.sh

# Auto-lock screen after 10 minutes of inactivity
# -time 10 = 10 minutes until lock
# -notify 30 = show warning 30 seconds before locking
# -t 10000 = notification timeout in milliseconds (10 seconds)
exec --no-startup-id xautolock -time 10 -locker "${HOME}/bin/do_lock.sh" -notify 30 -notifier "notify-send -u critical -t 10000 'Screen will lock in 30 seconds'"

# Turn off screens 6 minutes after lock (handled by xset dpms)
# Values are in seconds: 360 = 6 minutes (Standby, Suspend, Off)
exec --no-startup-id xset dpms 360 360 360

# Manual lock screen keybinding
bindsym Ctrl+mod1+L exec ${HOME}/bin/do_lock.sh
