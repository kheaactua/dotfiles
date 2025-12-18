#!/usr/bin/env fish
# Fish version of agents.dot - simplified for non-WSL usage

function clean_ssh_env
    set -e SSH_AGENT_PID
    set -e SSH_AUTH_SOCK
    set -e SSH_AUTH_AGENT
end

function check_agent_file
    set -l ssh_auth_sock $argv[1]
    if test -z "$ssh_auth_sock"
        set ssh_auth_sock $SSH_AUTH_SOCK
    end

    # Verify the SSH agent file is correct
    if test -z "$ssh_auth_sock"
        return 0
    end

    if not test -e "$ssh_auth_sock"
        return 0
    end

    if test -S "$ssh_auth_sock"
        set -l owner (stat -c %U "$ssh_auth_sock")
        if test "$owner" != "$USER"
            echo "SSH_AUTH_SOCK=$ssh_auth_sock has the wrong ownership: $owner"
            return 1
        end
    end

    return 0
end

function init_gpg_agent
    # Initialize GPG agent for SSH
    if test -z "$SSH_AUTH_SOCK"
        set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    end
    set -gx GPG_TTY (tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null
end

function init_keyring
    clean_ssh_env

    # Get the major version of gnome-keyring-daemon
    set -l gkversion (gnome-keyring-daemon --version 2>/dev/null | sed -n 's/.*gnome-keyring[^\s]*\s\(\([0-9]\+\)\.[0-9]\+\).*/\2/p')

    if test "$gkversion" -gt 46 2>/dev/null
        # Newer gnome-keyring versions (>46)
        set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/gcr/ssh"
    else
        # Older versions
        set -l keyring_output (gnome-keyring-daemon --start --components=ssh 2>/dev/null)
        for line in $keyring_output
            if string match -q "SSH_AUTH_SOCK=*" $line
                set -gx SSH_AUTH_SOCK (string replace "SSH_AUTH_SOCK=" "" $line)
                set -gx SSH_AUTH_AGENT $SSH_AUTH_SOCK
            end
        end
    end
end

# vim: sw=4 sts=0 ts=4 expandtab ff=unix ft=fish :
