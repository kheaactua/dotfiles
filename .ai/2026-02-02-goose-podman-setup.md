# Goose Podman Container Setup

**Date:** 2026-02-02  
**AI Tool:** goose (running in host environment, setting up containerized version)  
**Purpose:** Set up secure containerized goose environment to isolate AI operations from host system

## Changes Made

### Files Created/Modified

1. **`stow/fish/.config/fish/conf.d/goose-podman.fish`**
   - Fish function `goose-fsb` to run goose in Podman container
   - Mounts all necessary configs (git, SSH agent, API keys)
   - Configures proper UID mapping with `--userns=keep-id`
   - Includes corporate proxy support

2. **`~/workspace/docker/goose/`** (not in dotfiles, local only)
   - `Dockerfile` - Ubuntu 22.04 base with goose-ai installed
   - `patch_langfuse.py` - Fixes langfuse.decorators import bug
   - `build.sh` - Build script for the image
   - `README.md` - Complete setup documentation

3. **`.config/goose/profiles.yaml`** (in dotfiles-secret)
   - Created default profile configuration
   - Uses OpenAI with gpt-4o/gpt-4o-mini

## Security Benefits

### Why Run Goose in a Container?

Running goose (or any AI coding assistant) in a container provides important security isolation:

1. **Limited Filesystem Access**: Only explicitly mounted directories are accessible
2. **No Sudo Access to Host**: Container runs rootless with Podman
3. **Controlled Environment**: AI can only modify files in mounted locations
4. **Easy Cleanup**: Can destroy and rebuild container without affecting host
5. **Blast Radius Control**: Mistakes or bugs are contained within the container

### What's Mounted

- `~/.config/goose` - Session history and config (read-write with `:z`)
- Git configs (`.gitconfig*` excluding `.gitconfig-tools`)
- SSH agent socket (no private keys!)
- API tokens via environment variables
- Workspace directories (`/f/phoenix/phx-fsb`, FSB-specific dirs)
- Corporate proxy settings

### What's NOT Mounted

- Private SSH keys (agent handles authentication)
- `.gitconfig-tools` (references host-only binaries like delta, difftastic)
- Most of the home directory
- System directories

## Usage

```bash
# Start a new goose session
goose-fsb

# Resume most recent session
goose-fsb goose session resume

# List all sessions
goose-fsb goose session list

# Drop into bash for debugging
goose-fsb bash

# Pass any command
goose-fsb goose version
```

## Technical Details

### Podman vs Docker

Chose Podman for additional security:
- **Daemonless**: No root daemon running
- **Rootless by default**: Runs as your user
- **User namespaces**: Additional isolation layer
- **Compatible**: Same CLI and image format as Docker

### Langfuse Bug Fix

Goose 0.9.11 and ai-exchange 0.9.9 have a bug where they import `langfuse.decorators` which doesn't exist in langfuse 3.x. The Dockerfile includes a patch that creates a mock `langfuse_context` object to work around this issue.

### Image Tools

The container includes essential development tools:
- **Critical for goose**: ripgrep (rg), fd-find
- Git, curl, wget, ssh
- Python 3 with pip
- Build tools (gcc, make, cmake)
- Text editors (vim, nano)

## Recommendations

### For Other Users

If you want to run goose (or similar AI assistants) safely:

1. **Use containers**: Docker or Podman with explicit mounts
2. **Mount selectively**: Only what the AI needs access to
3. **Use SSH agent forwarding**: Don't mount private keys
4. **Enable `--userns=keep-id`**: Proper file permissions in Podman
5. **Consider separate environments**: Different functions for different projects

### Creating Additional Environments

The fish function includes a template for creating more environments:

```fish
function goose-web --description "Run goose for web projects"
    # Copy and modify the goose-fsb function
    # Change WORK_DIR and mounts as needed
end
```

This allows you to have isolated goose environments for different projects or security contexts.

## Future Improvements

Potential enhancements to consider:

- [ ] Network isolation (`--network none`) for offline work
- [ ] Resource limits (`--memory`, `--cpus`)
- [ ] Read-only mounts for reference code
- [ ] GPG agent forwarding for commit signing
- [ ] Multiple profile configurations for different providers

## References

- Goose documentation: https://github.com/block/goose
- Podman rootless: https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md
- Fish function location: `~/.config/fish/conf.d/goose-podman.fish`
