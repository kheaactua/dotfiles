# Goose with Podman - Container-based AI assistant environments
#
# Tools goose commonly uses:
# - git (version control)
# - rg/ripgrep (code search - CRITICAL)
# - fd (file finder)
# - curl/wget (downloads)
# - python3/pip (often needed)
# - jq (json processing)
# - build tools: make, cmake, gcc, g++, etc.
# - text editors: vim/nvim, nano
# - shell utilities: bash, fish, zsh

function goose-podman --description "Run goose in podman to isolate session from host"
    # Configuration - easy to modify
    set -l IMAGE "goose-ubuntu:latest"  # Or use "ubuntu:22.04" as base
    set -l CONTAINER_USER (id -u):(id -g)
    set -l WORK_DIR "/f/phoenix/phx-fsb"

    # Base command array - easier to read and modify
    set -l cmd podman run -it --rm

    # Container name (makes it easier to identify in podman ps)
    set -a cmd --name goose-podman

    # Keep user ID mapping for proper file permissions
    set -a cmd --userns=keep-id

    # User and working directory
    set -a cmd --user $CONTAINER_USER
    set -a cmd -w $WORK_DIR

    # Network mode - use host network like your compose file
    set -a cmd --network host

    # ========================================
    # Environment Variables
    # ========================================
    # Goose/LLM tokens
    test -n "$OPENAI_API_KEY" && set -a cmd -e OPENAI_API_KEY
    test -n "$OPENAI_API_BASE" && set -a cmd -e OPENAI_API_BASE
    # For GitHub Copilot: set OPENAI_HOST to https://api.githubcopilot.com (no trailing slash or /v1/)
    test -n "$OPENAI_HOST" && set -a cmd -e OPENAI_HOST
    test -n "$ANTHROPIC_API_KEY" && set -a cmd -e ANTHROPIC_API_KEY

    # Jira
    test -n "$JIRA_API_TOKEN" && set -a cmd -e JIRA_API_TOKEN
    test -n "$JIRA_EMAIL" && set -a cmd -e JIRA_EMAIL
    test -n "$JIRA_SERVER" && set -a cmd -e JIRA_SERVER

    # Git/GitHub
    test -n "$GITHUB_TOKEN" && set -a cmd -e GITHUB_TOKEN
    test -n "$WORK_GITHUB_TOKEN" && set -a cmd -e WORK_GITHUB_TOKEN

    # JFrog
    test -n "$JFROG_SH_TOKEN" && set -a cmd -e JFROG_SH_TOKEN
    test -n "$JFROG_EXT_TOKEN" && set -a cmd -e JFROG_EXT_TOKEN

    # SSH Agent
    test -n "$SSH_AUTH_SOCK" && set -a cmd -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock

    # GPG Agent (for commit signing)
    test -n "$GPG_TTY" && set -a cmd -e GPG_TTY
    # Note: GPG agent socket location varies by system
    # Common locations: ~/.gnupg/S.gpg-agent or /run/user/$(id -u)/gnupg/S.gpg-agent

    # Corporate proxy (for network access inside container)
    test -n "$http_proxy" && set -a cmd -e http_proxy
    test -n "$https_proxy" && set -a cmd -e https_proxy
    test -n "$no_proxy" && set -a cmd -e no_proxy

    # Disable langfuse telemetry (fixes import error with langfuse.decorators)
    set -a cmd -e LANGFUSE_ENABLED=false

    # Disable goose keyring (prevents gnome keyring errors in container)
    set -a cmd -e GOOSE_DISABLE_KEYRING=1

    # Terminal settings (for proper Ctrl-J and other key handling)
    test -n "$TERM" && set -a cmd -e TERM

    # Temporary directory (makes temp files accessible on host)
    set -a cmd -e TMPDIR=/home/matt/tmp

    # ========================================
    # Volume Mounts
    # ========================================
    # Goose config (persistent sessions, preferences)
    set -a cmd -v $HOME/.config/goose:/home/matt/.config/goose:z

    # SSH setup - agent socket, config, and known_hosts
    # Note: Private keys (id_rsa, id_ed25519) should NOT be mounted - the agent handles them
    test -e $HOME/.ssh/config && set -a cmd -v $HOME/.ssh/config:/home/matt/.ssh/config:ro
    test -e $HOME/.ssh/known_hosts && set -a cmd -v $HOME/.ssh/known_hosts:/home/matt/.ssh/known_hosts:ro
    test -n "$SSH_AUTH_SOCK" && set -a cmd -v $SSH_AUTH_SOCK:/run/host-services/ssh-auth.sock

    # Git credentials and config files
    # Mount all .gitconfig* files (main config uses includeIf to reference others)
    # Note: .gitconfig-tools is NOT mounted - it contains references to host-only tools (delta, difftastic, etc.)
    test -e $HOME/.gitconfig && set -a cmd -v $HOME/.gitconfig:/home/matt/.gitconfig:ro
    test -e $HOME/.gitconfig-dev && set -a cmd -v $HOME/.gitconfig-dev:/home/matt/.gitconfig-dev:ro
    test -e $HOME/.gitconfig-work && set -a cmd -v $HOME/.gitconfig-work:/home/matt/.gitconfig-work:ro
    test -e $HOME/.gitconfig-fsb && set -a cmd -v $HOME/.gitconfig-fsb:/home/matt/.gitconfig-fsb:ro
    test -e $HOME/.gitconfig-proxy && set -a cmd -v $HOME/.gitconfig-proxy:/home/matt/.gitconfig-proxy:ro
    test -e $HOME/.netrc && set -a cmd -v $HOME/.netrc:/home/matt/.netrc:ro
    test -e $HOME/.gitcookies && set -a cmd -v $HOME/.gitcookies:/home/matt/.gitcookies:ro
    test -e $HOME/.git-credentials && set -a cmd -v $HOME/.git-credentials:/home/matt/.git-credentials:ro

    # Primary workspace
    set -a cmd -v /f/phoenix/phx-fsb:/f/phoenix/phx-fsb

    # FSB-specific directories (from your compose file)
    test -d $HOME/.fsb_git_mirror && set -a cmd -v $HOME/.fsb_git_mirror:/home/matt/.fsb_git_mirror
    test -d $HOME/.fsb_dl_cache && set -a cmd -v $HOME/.fsb_dl_cache:/home/matt/.fsb_dl_cache
    test -d $HOME/.fsb-ccache && set -a cmd -v $HOME/.fsb-ccache:/home/matt/.fsb-ccache
    test -d $HOME/.pbos_local_srv_root_gcs && set -a cmd -v $HOME/.pbos_local_srv_root_gcs:/home/matt/.pbos_local_srv_root_gcs
    test -d $HOME/.pbos_local_srv_root_s3 && set -a cmd -v $HOME/.pbos_local_srv_root_s3:/home/matt/.pbos_local_srv_root_s3

    # QNX (if exists)
    test -d $HOME/.qnx && set -a cmd -v $HOME/.qnx:/home/matt/.qnx
    test -d $HOME/qnx && set -a cmd -v $HOME/qnx:/home/matt/qnx

    # Wireshark config (profiles, preferences, captures)
    test -d $HOME/.config/wireshark && set -a cmd -v $HOME/.config/wireshark:/home/matt/.config/wireshark

    # Temporary directory (accessible on host at ~/tmp)
    set -a cmd -v $HOME/tmp:/home/matt/tmp

    # GPG agent socket (for commit signing - uncomment if you use GPG)
    # test -S $HOME/.gnupg/S.gpg-agent && set -a cmd -v $HOME/.gnupg/S.gpg-agent:/home/matt/.gnupg/S.gpg-agent
    # Or if using /run/user based socket:
    # test -S /run/user/(id -u)/gnupg/S.gpg-agent && set -a cmd -v /run/user/(id -u)/gnupg/S.gpg-agent:/run/user/(id -u)/gnupg/S.gpg-agent

    # Timezone
    set -a cmd -v /etc/localtime:/etc/localtime:ro

    # ========================================
    # Image and command
    # ========================================
    set -a cmd $IMAGE

    # Pass through any arguments to goose
    if count $argv > /dev/null
        set -a cmd goose $argv
    else
        # Default: start an interactive goose session
        set -a cmd goose session
    end

    # Execute
    echo "🪿 Starting goose-podman in podman..."
    echo "Working directory: $WORK_DIR"
    eval $cmd
end

# Template for additional environments - uncomment and modify:
#
# function goose-web --description "Run goose for web development"
#     set -l IMAGE "ubuntu:22.04"
#     set -l CONTAINER_USER (id -u):(id -g)
#     set -l WORK_DIR "/home/matt/projects/web"
#
#     set -l cmd podman run -it --rm
#     set -a cmd --user $CONTAINER_USER
#     set -a cmd -w $WORK_DIR
#
#     # Environment variables
#     test -n "$OPENAI_API_KEY" && set -a cmd -e OPENAI_API_KEY
#     test -n "$ANTHROPIC_API_KEY" && set -a cmd -e ANTHROPIC_API_KEY
#
#     # Mounts
#     set -a cmd -v $HOME/.config/goose:/home/matt/.config/goose
#     set -a cmd -v $HOME/projects/web:/home/matt/projects/web
#
#     set -a cmd $IMAGE
#     test (count $argv) -gt 0 && set -a cmd $argv || set -a cmd goose session
#
#     eval $cmd
# end

# Quick reference for adding mounts:
# test -d /path/to/dir && set -a cmd -v /host/path:/container/path[:ro]
#
# Quick reference for adding env vars:
# test -n "\$VAR_NAME" && set -a cmd -e VAR_NAME
#
# Usage examples:
# goose-podman                    # Start interactive goose session
# goose-podman --help             # Pass arguments to goose
# goose-podman bash               # Drop into bash shell instead
