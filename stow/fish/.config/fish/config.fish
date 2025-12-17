# Initialize environment modules
if test -f /usr/share/modules/init/fish
    source /usr/share/modules/init/fish
end

# Load hostname-specific profile
if set -q DOTFILES_SECRET_DIR
    set -l hostname_profile "$DOTFILES_SECRET_DIR/profiles/"(hostname)".fish"
    if test -f "$hostname_profile"
        source "$hostname_profile"
    end
end

if status is-interactive
    # Commands to run in interactive sessions can go here
end
