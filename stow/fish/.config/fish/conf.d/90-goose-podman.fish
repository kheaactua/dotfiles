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

# ========================================
# Helper Functions (don't modify these unless you know what you're doing)
# ========================================

function __goose_print_verbose --description "Print verbose messages if GOOSE_CONTAINER_VERBOSE is set"
    if set -q GOOSE_CONTAINER_VERBOSE
        echo $argv 1>&2
    end
end

function __goose_mount_files --description "Mount files from list if they exist"
    set -l file_mounts $argv

    for mount in $file_mounts
        set -l parts (string split : $mount)
        set -l host_path $parts[1]
        if test -e $host_path
            echo "-v"
            echo $mount
            __goose_print_verbose "  📄 Mounting file: $mount"
        end
    end
end

function __goose_mount_directories --description "Mount directories and track paths"
    set -l dir_mounts $argv

    for mount in $dir_mounts
        set -l parts (string split : $mount)
        set -l host_path $parts[1]
        if test -e $host_path
            echo "-v"
            echo $mount
            echo "EXPLICIT_MOUNT:$host_path"
            __goose_print_verbose "  📁 Mounting directory: $mount"
        end
    end
end

function __goose_mount_workdir --description "Mount working directory or git root if not already covered"
    set -l work_dir $argv[1]
    set -l explicit_mount_list $argv[2..-1]

    # Check if current working directory is already covered by any mount
    set -l cwd_mounted false
    for mount_path in $explicit_mount_list
        if string match -q "$mount_path*" $work_dir
            set cwd_mounted true
            __goose_print_verbose "  ✓ Working directory already covered by mount: $mount_path"
            break
        end
    end

    # Mount current directory (or git root) if not already covered
    if test "$cwd_mounted" = false
        # Check if we're in a git repository
        set -l git_root (git rev-parse --show-toplevel 2>/dev/null)

        if test -n "$git_root"
            # We're in a git repo - mount the repository root instead of just cwd
            # This ensures .git and all repo files are accessible
            echo "-v"
            echo "$git_root:$git_root"
            echo "📂 Detected git repository, mounting: $git_root" 1>&2
        else
            # Not in a git repo - mount current directory
            echo "-v"
            echo "$work_dir:$work_dir"
            __goose_print_verbose "  📁 Mounting working directory: $work_dir"
        end
    end
end

function __goose_build_command --description "Build the final goose command from arguments"
    set -l image $argv[1]
    set -l work_dir $argv[2]
    set -l remaining_args $argv[3..-1]

    # Set working directory BEFORE the image
    echo "-w"
    echo $work_dir
    __goose_print_verbose "  📍 Working directory: $work_dir"

    # Add image to command
    echo $image

    # Pass through any arguments to goose (or run bash/other commands for debugging)
    if test (count $remaining_args) -gt 0
        # Check if first arg is 'bash' or other shell commands (for debugging)
        if test "$remaining_args[1]" = "bash" -o "$remaining_args[1]" = "sh" -o "$remaining_args[1]" = "fish"
            for arg in $remaining_args
                echo $arg
            end
            __goose_print_verbose "  🐚 Launching shell: $remaining_args[1]"
        else
            echo "goose"
            for arg in $remaining_args
                echo $arg
            end
            __goose_print_verbose "  🪿 Running: goose $remaining_args"
        end
    else
        # Default: start an interactive goose session
        echo "goose"
        echo "session"
        __goose_print_verbose "  🪿 Starting interactive goose session"
    end
end

# ========================================
# Main Function (customize this section)
# ========================================

function goose-container --description "Run goose in container to isolate session from host"
    # Configuration - easy to modify
    set -l IMAGE "goose-ubuntu:latest"
    set -l CONTAINER_USER "$(whoami)"
    set -l CONTAINER_HOME "/home/$CONTAINER_USER"
    set -l WORK_DIR (pwd)  # Use current working directory
    set -l HOST_TMP_DIR "$HOME/tmp"  # Temp directory (same path on host and container)

    # Base command array - easier to read and modify
    set -l cmd podman run -it --rm

    # Container name (makes it easier to identify in podman ps)
    set -l container_name "goose-podman-"(date +%H%M%S)
    set -a cmd --name $container_name

    # Keep user ID mapping for proper file permissions
    set -a cmd --userns=keep-id

    # User
    set -a cmd --user $CONTAINER_USER

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
        http_proxy https_proxy no_proxy ftp_proxy \
        HTTP_PROXY HTTPS_PROXY NO_PROXY FTP_PROXY \
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

    #
    # Always set these (not conditional)

    # Disable Langfuse telemetry - prevents sending usage data, prompts, and responses
    # to external analytics services (important for privacy and corporate security)
    set -a cmd -e LANGFUSE_ENABLED=false

    # Disable keyring - use environment variables for credentials instead
    # (keyring requires system-level access that may not work well in containers)
    set -a cmd -e GOOSE_DISABLE_KEYRING=1

    # Set temporary directory to avoid conflicts with mounting host /tmp
    # Uses same path on both host and container so temp files are accessible from both sides.
    # This is mounted as a volume below.
    set -a cmd -e TMPDIR=$HOST_TMP_DIR

    # ========================================
    # Volume Mounts
    # ========================================
    # Goose config (persistent sessions, preferences) - always mount
    set -a cmd -v $HOME/.config/goose:$CONTAINER_HOME/.config/goose

    # Define conditional file mounts (format: host_path:container_path:options)
    set -l file_mounts \
        $HOME/.ssh/config:$CONTAINER_HOME/.ssh/config:ro \
        $HOME/.ssh/known_hosts:$CONTAINER_HOME/.ssh/known_hosts:ro \
        $HOME/.gitconfig:$CONTAINER_HOME/.gitconfig:ro \
        $HOME/.gitconfig-dev:$CONTAINER_HOME/.gitconfig-dev:ro \
        $HOME/.gitconfig-work:$CONTAINER_HOME/.gitconfig-work:ro \
        $HOME/.gitconfig-proxy:$CONTAINER_HOME/.gitconfig-proxy:ro \
        $HOME/.netrc:$CONTAINER_HOME/.netrc:ro \
        $HOME/.gitcookies:$CONTAINER_HOME/.gitcookies:ro \
        $HOME/.git-credentials:$CONTAINER_HOME/.git-credentials:ro

    # Mount files if they exist (uses helper function)
    for item in (__goose_mount_files $file_mounts)
        set -a cmd $item
    end

    # SSH Agent socket - special handling
    if set -q SSH_AUTH_SOCK
        set -a cmd -v $SSH_AUTH_SOCK:/run/host-services/ssh-auth.sock
    end

    # Define directory mounts that should always be mounted (format: host:container)
    set -l always_dir_mounts \
        $HOST_TMP_DIR:$HOST_TMP_DIR \
        /etc/localtime:/etc/localtime:ro \
        (goose-podman-work-mounts $CONTAINER_HOME)  # Add work-specific mounts from function (if it exists)

    # Define conditional directory mounts (format: host:container)
    set -l conditional_dir_mounts \
        $HOME/.config/wireshark:$CONTAINER_HOME/.config/wireshark \
        $HOME/workspace/preprocess-jiras:$CONTAINER_HOME/workspace/preprocess-jiras

    # Add work-specific mounts (both files and directories) if function exists
    if type -q goose-podman-work-mounts
        for mount in (goose-podman-work-mounts)
            set -a conditional_dir_mounts $mount
        end
    end

    # Track explicit mounts for duplicate detection
    set -l explicit_mounts

    # Mount directories and track paths (uses helper function)
    for result in (__goose_mount_directories $always_dir_mounts)
        if string match -q "EXPLICIT_MOUNT:*" $result
            set -l path (string sub -s 16 $result)
            set -a explicit_mounts $path
        else
            set -a cmd $result
        end
    end

    for result in (__goose_mount_directories $conditional_dir_mounts)
        if string match -q "EXPLICIT_MOUNT:*" $result
            set -l path (string sub -s 16 $result)
            set -a explicit_mounts $path
        else
            set -a cmd $result
        end
    end

    # Mount working directory or git root if not already covered (uses helper function)
    for item in (__goose_mount_workdir $WORK_DIR $explicit_mounts)
        set -a cmd $item
    end

    # ========================================
    # Build final command and execute
    # ========================================
    __goose_print_verbose ""
    __goose_print_verbose "🪿 Container Configuration:"
    __goose_print_verbose "  Image: $IMAGE"
    __goose_print_verbose "  User: $CONTAINER_USER"
    __goose_print_verbose "  Container name: $container_name"
    __goose_print_verbose ""

    # Build the final command (adds image, working directory, and goose command)
    for item in (__goose_build_command $IMAGE $WORK_DIR $argv)
        set -a cmd $item
    end

    # Execute
    echo "🪿 Starting goose-container..."
    echo "Working directory: $WORK_DIR"
    __goose_print_verbose ""
    __goose_print_verbose "Full command:"
    __goose_print_verbose "  $cmd"
    __goose_print_verbose ""
    eval $cmd
end

# Template for additional environments - uncomment and modify:
#
# function goose-web --description "Run goose for web development"
#     set -l IMAGE "goose-ubuntu:latest"
#     set -l CONTAINER_USER "developer"
#     set -l CONTAINER_HOME "/home/$CONTAINER_USER"
#
#     set -l cmd podman run -it --rm
#     set -a cmd --userns=keep-id
#     set -a cmd -v $PWD:/workspace -w /workspace
#
#     # Environment variables
#     test -n "$OPENAI_API_KEY" && set -a cmd -e OPENAI_API_KEY
#     test -n "$ANTHROPIC_API_KEY" && set -a cmd -e ANTHROPIC_API_KEY
#
#     # Mounts
#     set -a cmd -v $HOME/.config/goose:$CONTAINER_HOME/.config/goose
#     set -a cmd -v $HOME/.ssh:$CONTAINER_HOME/.ssh:ro
#     set -a cmd -v $HOME/.gitconfig:$CONTAINER_HOME/.gitconfig:ro
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
# goose-container                 # Start interactive goose session
# goose-container --help          # Pass arguments to goose
# goose-container bash            # Drop into bash shell instead
