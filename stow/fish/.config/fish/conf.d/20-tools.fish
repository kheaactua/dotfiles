# Initialize zoxide (smarter cd command)
if type -q zoxide
    zoxide init fish | source
    # Optional: also load custom config if it exists
    if test -e "$HOME/.config/zoxide/zoxide.fish"
        source "$HOME/.config/zoxide/zoxide.fish"
    end
end

# Initialize direnv (automatic environment switching)
if type -q direnv
    direnv hook fish | source
end
