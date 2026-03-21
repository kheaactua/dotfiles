# Linuxbrew/Homebrew setup
# Use the official `brew shellenv` for proper initialization

if test -e "$HOME/.linuxbrew/bin/brew"
    eval ("$HOME/.linuxbrew/bin/brew" shellenv)
else if test -e /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end
