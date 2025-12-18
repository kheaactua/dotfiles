# Set TERMINAL
if type -q urxvt
    set -gx TERMINAL urxvt
end
# Prefer kitty if available
if type -q kitty
    set -gx TERMINAL kitty
end

# Set EDITOR
if type -q nvim
    set -gx EDITOR nvim
end

# Set up FZF_DEFAULT_COMMAND
if type -q fd
    set -gx FZF_DEFAULT_COMMAND "fd --type f"
else if type -q fdfind
    set -gx FZF_DEFAULT_COMMAND "fdfind --type f"
end

# Set up ripgconfig
set -gx RIPGREP_CONFIG_PATH "$HOME/.config/ripgrep/ripgreprc"
