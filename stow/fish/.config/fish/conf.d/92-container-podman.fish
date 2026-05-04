# Generic Container Launcher with Podman - For Goose, Copilot, and other AI tools
#
# Tools commonly used by AI assistants:
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

function __container_print_verbose --description "Print verbose messages if CONTAINER_VERBOSE is set"
    if set -q CONTAINER_VERBOSE
        echo $argv 1>&2
    end
end

function __container_mount_files --description "Mount files from list if they exist"
    set -l file_mounts $argv

    for mount in $file_mounts
        set -l parts (string split : $mount)
        set -l host_path $parts[1]
        if test -e $host_path
            echo "-v"
            echo $mount
            __container_print_verbose "  📄 Mounting file: $mount"
        end
    end
end

function __container_mount_directories --description "Mount directories and files, tracking paths"
    set -l dir_mounts $argv

    for mount in $dir_mounts
        set -l parts (string split : $mount)
        set -l host_path $parts[1]
        if test -e $host_path
            echo "-v"
            echo $mount
            echo "EXPLICIT_MOUNT:$host_path"
            # Check if it's a file or directory for proper emoji
            if test -f $host_path
                __container_print_verbose "  📄 Mounting file: $mount"
            else if test -d $host_path
                __container_print_verbose "  📁 Mounting directory: $mount"
            else
                __container_print_verbose "  📦 Mounting: $mount"
            end
        end
    end
end

function __container_mount_workdir --description "Mount working directory or git root if not already covered"
    set -l work_dir $argv[1]
    set -l explicit_mount_list $argv[2..-1]

    # Check if current working directory is already covered by any mount
    set -l cwd_mounted false
    for mount_path in $explicit_mount_list
        if string match -q "$mount_path*" $work_dir
            set cwd_mounted true
            __container_print_verbose "  ✓ Working directory already covered by mount: $mount_path"
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
            __container_print_verbose "  📁 Mounting working directory: $work_dir"
        end
    end
end

function __container_build_command --description "Build the final container command from arguments"
    set -l image $argv[1]
    set -l work_dir $argv[2]
    set -l tool_cmd $argv[3]
    set -l remaining_args $argv[4..-1]

    # Set working directory BEFORE the image
    echo "-w"
    echo $work_dir
    __container_print_verbose "  📍 Working directory: $work_dir"

    # Add image to command
    echo $image

    # Pass through any arguments to entrypoint (or run bash/other commands for debugging)
    if test (count $remaining_args) -gt 0
        # Check if first arg is 'bash' or other shell commands (for debugging)
        if test "$remaining_args[1]" = "bash" -o "$remaining_args[1]" = "sh" -o "$remaining_args[1]" = "fish"
            for arg in $remaining_args
                echo $arg
            end
            __container_print_verbose "  🐚 Launching shell: $remaining_args[1]"
        else
            echo $tool_cmd
            for arg in $remaining_args
                echo $arg
            end
            __container_print_verbose "  🚀 Running: $tool_cmd $remaining_args"
        end
    else
        # Default behavior depends on the tool
        echo $tool_cmd
        if test "$tool_cmd" = "goose"
            echo "session"
            __container_print_verbose "  🚀 Starting interactive goose session"
        else if test "$tool_cmd" = "copilot"
            # copilot with no args starts interactive mode
            __container_print_verbose "  🚀 Starting interactive copilot session"
        else
            __container_print_verbose "  🚀 Running $tool_cmd"
        end
    end
end

# ========================================
# Generic Container Launcher (customize this section)
# ========================================

function __container_launcher --description "Generic container launcher with common mounts and env vars"
    # Parse arguments
    set -l IMAGE $argv[1]
    set -l TOOL_CMD $argv[2]
    set -l remaining_args $argv[3..-1]

    # Validate required arguments
    if test -z "$IMAGE" -o -z "$TOOL_CMD"
        echo "Error: __container_launcher requires IMAGE and TOOL_CMD" >&2
        return 1
    end

    # Configuration
    set -l CONTAINER_USER "$(whoami)"
    set -l CONTAINER_HOME "/home/$CONTAINER_USER"
    set -l WORK_DIR (pwd)  # Use current working directory

    # Base command array - easier to read and modify
    set -l cmd podman run -it --rm

    # Container name (makes it easier to identify in podman ps)
    set -l container_name "$TOOL_CMD-podman-"(date +%H%M%S)
    set -a cmd --name $container_name

    # Container-specific tmpdir - unique per container to avoid collisions
    # Mounted at same path on host and container for consistency
    set -l CONTAINER_TMPDIR "$HOME/tmp/sessions/$container_name"
    mkdir -p $CONTAINER_TMPDIR  # Create on host before mounting
    __container_print_verbose "  📁 Created container tmpdir: $CONTAINER_TMPDIR"

    # Keep user ID mapping for proper file permissions
    set -a cmd --userns=keep-id

    # User
    set -a cmd --user $CONTAINER_USER

    # Network mode - use host network
    set -a cmd --network host

    # ========================================
    # Environment Variables
    # ========================================
    # Define environment variables to pass through (if they exist)
    set -l env_vars_to_pass \
        OPENAI_API_KEY OPENAI_API_BASE OPENAI_HOST ANTHROPIC_API_KEY \
        ATLASSIAN_API_TOKEN ATLASSIAN_EMAIL ATLASSIAN_BASE_URL \
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

    # Add work-specific environment variables if function exists
    if type -q container-work-env-vars
        for env_var in (container-work-env-vars)
            set -l parts (string split = $env_var)
            set -l var_name $parts[1]
            set -l var_value $parts[2]
            set -a cmd -e $var_name=$var_value
            __container_print_verbose "  🔑 Setting env: $var_name=$var_value"
        end
    end

    # SSH Agent - needs special handling for socket path
    if set -q SSH_AUTH_SOCK
        set -a cmd -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock
    end

    #
    # Always set these (not conditional)

    # Set TMPDIR for the process to use container-specific temp directory
    # This only affects the tool, not other container processes (which use their own /tmp)
    # Mounted at same path on host and container for easy access from both sides
    set -a cmd -e TMPDIR=$CONTAINER_TMPDIR

    # ========================================
    # Volume Mounts
    # ========================================
    # Container-specific tmpdir (mounted before other dirs to ensure it's available)
    set -a cmd -v $CONTAINER_TMPDIR:$CONTAINER_TMPDIR
    __container_print_verbose "  📁 Mounting tmpdir: $CONTAINER_TMPDIR"

    # Tool config directories (persistent sessions, preferences) - always mount
    set -a cmd -v $HOME/.config/goose:$CONTAINER_HOME/.config/goose
    set -a cmd -v $HOME/.config/github-copilot:$CONTAINER_HOME/.config/github-copilot
    set -a cmd -v $HOME/.copilot:$CONTAINER_HOME/.copilot

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
    for item in (__container_mount_files $file_mounts)
        set -a cmd $item
    end

    # SSH Agent socket - special handling
    if set -q SSH_AUTH_SOCK
        set -a cmd -v $SSH_AUTH_SOCK:/run/host-services/ssh-auth.sock
    end

    # Define directory mounts that should always be mounted (format: host:container)
    set -l always_dir_mounts \
        /etc/localtime:/etc/localtime:ro \
        $HOME/tmp:$CONTAINER_HOME/tmp

    # Define conditional directory mounts (format: host:container)
    set -l conditional_dir_mounts \
        $HOME/.config/gh:$CONTAINER_HOME/.config/gh \
        $HOME/.config/wireshark:$CONTAINER_HOME/.config/wireshark \
        $HOME/workspace/preprocess-jiras:$CONTAINER_HOME/workspace/preprocess-jiras

    # Add work-specific mounts (both files and directories) if function exists
    if type -q container-work-mounts
        for mount in (container-work-mounts)
            set -a conditional_dir_mounts $mount
        end
    end

    # Track explicit mounts for duplicate detection
    set -l explicit_mounts

    # Mount directories and track paths (uses helper function)
    for result in (__container_mount_directories $always_dir_mounts)
        if string match -q "EXPLICIT_MOUNT:*" $result
            # set -l path (string sub -s 16 $result)
            set -a explicit_mounts $path
        else
            set -a cmd $result
        end
    end

    for result in (__container_mount_directories $conditional_dir_mounts)
        if string match -q "EXPLICIT_MOUNT:*" $result
            set -l path (string sub -s 16 $result)
            set -a explicit_mounts $path
        else
            set -a cmd $result
        end
    end

    # Mount working directory or git root if not already covered (uses helper function)
    for item in (__container_mount_workdir $WORK_DIR $explicit_mounts)
        set -a cmd $item
    end

    # ========================================
    # Build final command and execute
    # ========================================
    __container_print_verbose ""
    __container_print_verbose "🚀 Container Configuration:"
    __container_print_verbose "  Tool: $TOOL_CMD"
    __container_print_verbose "  Image: $IMAGE"
    __container_print_verbose "  User: $CONTAINER_USER"
    __container_print_verbose "  Container name: $container_name"
    __container_print_verbose ""

    # Build the final command (adds image, working directory, and entrypoint command)
    for item in (__container_build_command $IMAGE $WORK_DIR $TOOL_CMD $remaining_args)
        set -a cmd $item
    end

    # Execute
    echo "🚀 Starting $TOOL_CMD container..."
    echo "Working directory: $WORK_DIR"
    __container_print_verbose ""
    __container_print_verbose "Full command:"
    __container_print_verbose "  $cmd"
    __container_print_verbose ""
    eval $cmd
end

# ========================================
# Tool-Specific Wrappers
# ========================================

function goose-container --description "Run goose in container to isolate session from host"
    # Set goose-specific environment variables
    set -x GOOSE_DISABLE_KEYRING 1
    set -x LANGFUSE_ENABLED false

    # Pass through GOOSE_MOIM_MESSAGE_TEXT if it exists
    if set -q GOOSE_MOIM_MESSAGE_TEXT
        set -x GOOSE_MOIM_MESSAGE_TEXT "$GOOSE_MOIM_MESSAGE_TEXT"
    end

    __container_launcher "ai-ubuntu:latest" "goose" $argv

    # Clean up exported variables
    set -e GOOSE_DISABLE_KEYRING
    set -e LANGFUSE_ENABLED
    if set -q GOOSE_MOIM_MESSAGE_TEXT
        set -e GOOSE_MOIM_MESSAGE_TEXT
    end
end

function copilot-container --description "Run GitHub Copilot CLI in container"
    # Copilot uses OAuth from gh auth login, not PATs
    # No need to set GH_TOKEN - it uses ~/.config/gh/ OAuth tokens

    __container_launcher "ai-ubuntu:latest" "copilot" $argv
end

# Backwards compatibility alias
function goose-podman --description "Alias for goose-container (backwards compatibility)"
    goose-container $argv
end

# Template for additional tool containers - uncomment and modify:
#
# function my-tool-container --description "Run my-tool in container"
#     __container_launcher "goose-ubuntu:latest" "my-tool" "my-tool" $argv
# end

# Quick reference for the generic launcher:
# __container_launcher IMAGE ENTRYPOINT_CMD TOOL_NAME [args...]
#
# Examples:
# __container_launcher "goose-ubuntu:latest" "goose" "goose" session --profile dev
# __container_launcher "goose-ubuntu:latest" "gh" "copilot" "copilot" "explain this code"
#
# Usage examples:
# goose-container                 # Start interactive goose session
# goose-container --help          # Pass arguments to goose
# goose-container bash            # Drop into bash shell instead
# copilot-container               # Start GitHub Copilot CLI
# copilot-container explain       # Run copilot with "explain" command
