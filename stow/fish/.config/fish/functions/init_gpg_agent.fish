function init_gpg_agent
    # Initialize GPG agent for SSH
    if test -z "$SSH_AUTH_SOCK"
        set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
    end
    set -gx GPG_TTY (tty)
    gpg-connect-agent updatestartuptty /bye >/dev/null
end

# vim: sw=4 sts=0 ts=4 expandtab ff=unix ft=fish :
