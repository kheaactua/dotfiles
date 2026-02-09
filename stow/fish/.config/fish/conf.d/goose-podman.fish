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
    set -l WORK_DIR (pwd)  # Use current working directory

    # Base command array - easier to read and modify
    set -l cmd podman run -it --rm

    # Container name (makes it easier to identify in podman ps)
    set -l container_name "goose-podman-"(date +%H%M%S)
    set -a cmd --name $container_name

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
    # Define environment variables to pass through (if they exist)
    set -l env_vars_to_pass \
        OPENAI_API_KEY OPENAI_API_BASE OPENAI_HOST ANTHROPIC_API_KEY \
        JIRA_API_TOKEN JIRA_EMAIL JIRA_SERVER \
        GITHUB_TOKEN WORK_GITHUB_TOKEN \
        JFROG_SH_TOKEN JFROG_EXT_TOKEN \
        GPG_TTY \
        http_proxy https_proxy no_proxy \
        TERM

    # Pass through environment variables if they exist
    for var in $env_vars_to_pass
        if set -q $var
            set -a cmd -e $var
        end
    end

    # SSH Agent - needs special handling for socket path
    if set -q SSH_AUTH_SOCK
        set -a cmd -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock
    end

    # Always set these (not conditional)
    set -a cmd -e LANGFUSE_ENABLED=false  # Disable langfuse telemetry
    set -a cmd -e GOOSE_DISABLE_KEYRING=1  # Disable goose keyring
    set -a cmd -e TMPDIR=/home/matt/tmp  # Temporary directory

    # ========================================
    # Volume Mounts
    # ========================================
    # Goose config (persistent sessions, preferences) - always mount
    set -a cmd -v $HOME/.config/goose:/home/matt/.config/goose:z

    # Define conditional file mounts (format: host_path:container_path:options)
    set -l file_mounts \
        $HOME/.ssh/config:/home/matt/.ssh/config:ro \
        $HOME/.ssh/known_hosts:/home/matt/.ssh/known_hosts:ro \
        $HOME/.gitconfig:/home/matt/.gitconfig:ro \
        $HOME/.gitconfig-dev:/home/matt/.gitconfig-dev:ro \
        $HOME/.gitconfig-work:/home/matt/.gitconfig-work:ro \
        $HOME/.gitconfig-fsb:/home/matt/.gitconfig-fsb:ro \
        $HOME/.gitconfig-proxy:/home/matt/.gitconfig-proxy:ro \
        $HOME/.netrc:/home/matt/.netrc:ro \
        $HOME/.gitcookies:/home/matt/.gitcookies:ro \
        $HOME/.git-credentials:/home/matt/.git-credentials:ro

    # Mount files if they exist
    for mount in $file_mounts
        set -l parts (string split : $mount)
        set -l host_path $parts[1]
        if test -e $host_path
            set -a cmd -v $mount
        end
    end

    # SSH Agent socket - special handling
    if set -q SSH_AUTH_SOCK
        set -a cmd -v $SSH_AUTH_SOCK:/run/host-services/ssh-auth.sock
    end

    # Define directory mounts that should always be mounted (format: host:container)
    set -l always_dir_mounts \
        /f/phoenix/phx-fsb:/f/phoenix/phx-fsb \
        /f/phoenix/aosp:/f/phoenix/aosp \
        $HOME/workspace/preprocess-jiras:/home/matt/workspace/preprocess-jiras \
        $HOME/tmp:/home/matt/tmp \
        /etc/localtime:/etc/localtime:ro

    # Define conditional directory mounts (format: host:container)
    set -l conditional_dir_mounts \
        $HOME/.fsb_git_mirror:/home/matt/.fsb_git_mirror \
        $HOME/.fsb_dl_cache:/home/matt/.fsb_dl_cache \
        $HOME/.fsb-ccache:/home/matt/.fsb-ccache \
        $HOME/.pbos_local_srv_root_gcs:/home/matt/.pbos_local_srv_root_gcs \
        $HOME/.pbos_local_srv_root_s3:/home/matt/.pbos_local_srv_root_s3 \
        $HOME/.qnx:/home/matt/.qnx \
        $HOME/qnx:/home/matt/qnx \
        $HOME/.config/wireshark:/home/matt/.config/wireshark

    # Collect all mount paths for duplicate detection
    set -l explicit_mounts

    # Add always mounts to command and collect their paths
    for mount in $always_dir_mounts
        set -l parts (string split : $mount)
        set -l host_path $parts[1]
        set -a cmd -v $mount
        set -a explicit_mounts $host_path
    end

    # Add conditional mounts if they exist
    for mount in $conditional_dir_mounts
        set -l parts (string split : $mount)
        set -l host_path $parts[1]
        if test -d $host_path
            set -a cmd -v $mount
            set -a explicit_mounts $host_path
        end
    end

    # Check if current working directory is already covered by any mount
    set -l cwd_mounted false
    for mount_path in $explicit_mounts
        if string match -q "$mount_path*" $WORK_DIR
            set cwd_mounted true
            break
        end
    end

    # Mount current directory if not already covered
    if test "$cwd_mounted" = false
        set -a cmd -v $WORK_DIR:$WORK_DIR
    end

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
