# Load hostname-specific profile
if set -q DOTFILES_SECRET_DIR
    set -l hostname_profile "$DOTFILES_SECRET_DIR/profiles/"(hostname)".fish"
    if test -f "$hostname_profile"
        source "$hostname_profile"
    end
end
