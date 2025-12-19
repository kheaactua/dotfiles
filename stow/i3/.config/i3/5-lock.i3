# Screen timeout and lock configuration

# xss-lock grabs a logind suspend inhibit lock and will use i3lock-color to lock the
# screen before suspend. Use loginctl lock-session to lock your screen.
exec --no-startup-id xss-lock --transfer-sleep-lock -- ${HOME}/bin/do_lock.sh

# Auto-lock screen after 5 minutes of inactivity
# Screen will turn off 1 minute after locking (total 6 minutes idle)
exec --no-startup-id xautolock -time 10 -locker "${HOME}/bin/do_lock.sh" -notify 30 -notifier "notify-send -u critical -t 10000 'Screen will lock in 30 seconds'"

# Turn off screens 1 minute after lock (handled by xset dpms)
exec --no-startup-id xset dpms 360 360 360

# Manual lock screen keybinding
bindsym Ctrl+mod1+L exec ${HOME}/bin/do_lock.sh
