# Set up DOTFILES_DIR if not already set
if not set -q DOTFILES_DIR
    set -gx DOTFILES_DIR "$HOME/dotfiles"
end

# Update the dotfiles repo to make sure we have all changes:
if test -e "$DOTFILES_DIR/doupdate.fish"
    source "$DOTFILES_DIR/doupdate.fish" > /dev/null 2>&1
end
