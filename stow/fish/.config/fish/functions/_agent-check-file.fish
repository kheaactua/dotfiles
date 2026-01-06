function _agent-check-file
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

# vim: sw=4 sts=0 ts=4 expandtab ff=unix ft=fish :
