function agent-init-keyring
    _clean-ssh-env

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
