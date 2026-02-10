# Separating Work-Specific Fish Configuration

## Summary

Successfully separated work-specific paths from the public dotfiles repository using function-based approach. The public `goose-podman.fish` remains unchanged except for checking if work functions exist.

## Changes Made

### 1. Created Work-Specific Function Files
Created in `~/dotfiles/dotfiles-secret/work/stow/fish-work/.config/fish-work/functions/`:
- `goose-podman-work-gitconfigs.fish` - Returns work gitconfig files
- `goose-podman-work-mounts.fish` - Returns work directory mounts

### 2. Work Paths Extracted
Each function returns specific paths via `echo`:

**goose-podman-work-gitconfigs:**
- `~/.gitconfig-fsb`

**goose-podman-work-mounts:**
- FSB: `/f/phoenix/phx-fsb`, `~/.fsb_git_mirror`, `~/.fsb_dl_cache`, `~/.fsb-ccache`
- PBOS: `~/.pbos_local_srv_root_gcs`, `~/.pbos_local_srv_root_s3`
- QNX: `~/.qnx`, `~/qnx`
- Phoenix: `/f/phoenix/aosp`

### 3. Modified Public goose-podman.fish
Updated to check for work functions using `type -q`:
```fish
if type -q goose-podman-work-gitconfigs
    for file in (goose-podman-work-gitconfigs)
        set -a file_mounts $file
    end
end

if type -q goose-podman-work-mounts
    for mount in (goose-podman-work-mounts)
        set -a conditional_dir_mounts $mount
    end
end
```

### 4. Added Automatic Function Loading
The existing `99-work-config.fish` adds `~/.config/fish-work/functions` to `fish_function_path`, enabling automatic function discovery.

## How It Works

1. Fish shell sources `99-work-config.fish` at startup
2. This adds `~/.config/fish-work/functions/` to the function search path
3. When `goose-podman` runs, it checks if work functions exist using `type -q`
4. If functions exist, they're called and paths are added
5. If functions don't exist (personal machines), they're silently skipped

## Benefits

✅ **Clean separation** - Work paths are in private repo  
✅ **No dependencies** - Public config works without work config  
✅ **Function-based** - Each function returns paths via `echo`  
✅ **Auto-loaded** - Fish handles function discovery automatically  
✅ **Easy to extend** - Add new functions for other work-specific configs  
✅ **Type-safe** - Uses `type -q` to check function existence  

## Testing

```bash
# Verify functions are accessible
fish -c 'set -g fish_function_path ~/.config/fish-work/functions $fish_function_path; \
         type -q goose-podman-work-gitconfigs && echo "✓ gitconfigs found"'

# Test function output
fish -c 'set -g fish_function_path ~/.config/fish-work/functions $fish_function_path; \
         goose-podman-work-mounts | head -3'
```

## Adding New Work Paths

Simply edit the function files and add more `echo` statements:

```fish
# In goose-podman-work-mounts.fish
function goose-podman-work-mounts
    echo "/existing/path:/existing/path"
    echo "/new/work/path:/new/work/path"  # Add this
end
```
