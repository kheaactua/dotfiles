# Polybar + i3wm + Autorandr Setup

## Summary

Successfully integrated Polybar with i3wm, with automatic display management through autorandr.

## Architecture

### Instead of the old flow:
```
autorandr postswitch.sh → modifies launch.sh → launches polybar
```

### We now have:
```
autorandr → postswitch.py → directly launches polybar with correct monitor
```

## Key Components

### 1. Polybar Configuration (`~/.config/polybar/config.ini`)
- **Monitor selection**: Uses `${env:MONITOR:}` variable
- **Modules**: i3 workspaces, CPU, memory, network, battery, date/time, audio
- **Theme**: Gruvbox-inspired colors
- **Tray**: System tray on the right side

### 2. Python Postswitch Script (`~/.config/autorandr/postswitch.py`)

A unified script that handles:

#### Display Management
- Detects all connected monitors using `xrandr`
- Categorizes monitors by position (left, center, right)
- Handles hostname-specific configurations

#### Workspace Arrangement
- Automatically assigns i3 workspaces to monitors:
  - **Left monitor**: workspaces 1, 8
  - **Center monitor**: workspaces 2, 4-7, 9-10
  - **Right monitor**: workspaces 3, 11-12

#### Polybar Management
- Smart monitor selection priority:
  1. Ultrawide (3440x1440) - **DP-1-2**
  2. Wide screen (2560x1080) - **DP-1-1**
  3. Any other external monitor
  4. Laptop screen (eDP-1)
- Launches Polybar with `MONITOR` environment variable
- Handles cleanup of old instances

#### Background Management
- Sets random wallpaper from `~/Desktop/Backgrounds/` using `feh`

### 3. i3 Configuration (`~/.config/i3/0-common-base.i3`)
- i3bar **disabled** (commented out)
- Polybar launches via `exec_always` (for manual reload compatibility)
- Note: autorandr's postswitch takes priority when displays change

## How It Works

### Environment Variables
The `MONITOR` variable is passed to Polybar like this:

```python
env = os.environ.copy()
env['MONITOR'] = 'DP-1-2'  # Selected monitor
subprocess.Popen(['polybar', '--reload', 'main'], env=env)
```

Then Polybar reads it in `config.ini`:
```ini
[bar/main]
monitor = ${env:MONITOR:}
```

This tells Polybar which physical monitor to display on.

### The `--reload main` Arguments
- `--reload`: Reload config if already running (though we kill first)
- `main`: The bar configuration name from `[bar/main]` section

## Usage

### Manual Trigger
```bash
python3 ~/.config/autorandr/postswitch.py
```

### Automatic Trigger
- Runs automatically when autorandr detects display changes
- Currently linked for profile: `laptop1_11_12`

### Add to More Profiles
```bash
cd ~/.config/autorandr/<profile_name>/
ln -sf ../postswitch.py postswitch
```

### Check Logs
```bash
tail -f /tmp/i3_autorandr_debug.log
tail -f /tmp/polybar_DP-1-2.log  # Replace with your monitor name
```

## Customization

### Change Polybar Monitor Priority
Edit `PolybarManager.select_monitor_for_polybar()` in `postswitch.py`

### Change Workspace Assignments
Edit `WORKSPACE_ASSIGNMENTS` dict in `DisplayManager.arrange_workspaces()`

### Change Polybar Appearance
Edit `~/.config/polybar/config.ini`:
- Colors: `[colors]` section
- Modules: `modules-left/center/right` in `[bar/main]`
- Height/position: `[bar/main]` parameters

### Add Hostname-Specific Configuration
Edit `MONITOR_CONFIGS` dict in `DisplayManager.categorize_monitors()`

## Files That Can Be Removed

These are now obsolete:
- `~/.config/polybar/launch.sh` - replaced by Python script
- `~/.config/autorandr/polybar-config.sh` - replaced by Python script
- Old `~/.config/autorandr/*/postswitch` shell scripts (if you symlink all profiles)

## Benefits of Python Approach

1. **Type safety**: Dataclasses and type hints
2. **Easier data handling**: Native dicts, lists instead of bash arrays
3. **Better error handling**: Try/except with logging
4. **More readable**: Object-oriented design
5. **Easier to extend**: Add new features without bash complexity
6. **No JSON/string parsing headaches**: Native JSON support

## Current Monitor Setup (UGC147YVDS3)

- **eDP-1** (Primary): 1366x768 - Laptop screen → Right workspaces (3, 11, 12)
- **DP-1-1**: 2560x1080 - External → Left workspaces (1, 8)
- **DP-1-2**: 3440x1440 - Ultrawide → Center workspaces (2, 4-10) + **Polybar**

## Troubleshooting

### Polybar not showing
```bash
# Check if running
pgrep -a polybar

# Check logs
tail -50 /tmp/polybar_*.log

# Manually test
MONITOR=DP-1-2 polybar --reload main
```

### Workspaces not moving
```bash
# Check detection
python3 ~/.config/autorandr/postswitch.py

# Check logs
cat /tmp/i3_autorandr_debug.log
```

### Wrong monitor selected
Edit the priority logic in `PolybarManager.select_monitor_for_polybar()`
