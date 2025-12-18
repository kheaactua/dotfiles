# Set up DOTFILES_DIR if not already set
if not set -q DOTFILES_DIR
    set -gx DOTFILES_DIR "$HOME/dotfiles"
end
if not set -q DOTFILES_SECRET_DIR
    set -gx DOTFILES_SECRET_DIR "$DOTFILES_DIR/dotfiles-secret"
end
