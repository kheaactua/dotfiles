# 2026-01-15 - VNC/i3 Login Conflict Investigation

**Date**: 2026-01-15  
**Time**: 08:42  
**Tool**: goose

## Problem

Unable to login to i3 on physical display after boot - error message saying "session is already running".

## Root Cause

1. VNC servers (`vncserver@:1` and `vncserver@:2`) were auto-starting at boot
2. Recent change to `.xinitrc` added `exec i3`, which VNC sessions were using
3. VNC config had `session=lxqt` but `.xinitrc` was overriding to launch i3
4. Two i3 instances were running in VNC sessions (PIDs 1141, 2088)
5. When trying to login on physical display, i3 detected existing instances and refused to start

## Investigation Results

- VNC hadn't been used in years but was still enabled at boot
- `.xinitrc` was recently modified from keyboard settings to `exec i3`
- VNC config in `~/.vnc/config` still set to `session=lxqt`

## Resolution

VNC services disabled for now:
```bash
sudo systemctl disable vncserver@:1.service
sudo systemctl disable vncserver@:2.service
sudo systemctl stop vncserver@:1.service
sudo systemctl stop vncserver@:2.service
```

## Future: Running VNC with i3

**Decision: Use xstartup script (Option 2)**

When VNC is re-enabled, i3 will be configured via `~/.vnc/xstartup`:

```bash
#!/bin/sh
exec i3
```

### Why xstartup over editing session config:
1. **Symmetry**: Matches the approach used in `.xinitrc` for physical display
2. **Flexibility**: Easy to add VNC-specific customizations later (different monitor configs, backgrounds, etc.)
3. **Independence**: Works regardless of system session files
4. **Control**: Complete control over VNC startup environment

Each X display (`:0` physical, `:1` `:2` VNC) will run separate i3 instances without conflict.

### To re-enable VNC with i3:
```bash
# Create xstartup file
cat > ~/.vnc/xstartup << 'EOF'
#!/bin/sh
exec i3
EOF
chmod +x ~/.vnc/xstartup

# Enable and start VNC services
sudo systemctl enable vncserver@:1.service
sudo systemctl enable vncserver@:2.service
sudo systemctl start vncserver@:1.service
sudo systemctl start vncserver@:2.service
```

## Files Referenced

- `stow/xinit/.xinitrc` - Changed to exec i3
- `~/.vnc/config` - VNC session configuration
- `/etc/systemd/system/vncserver@.service` - VNC systemd unit
