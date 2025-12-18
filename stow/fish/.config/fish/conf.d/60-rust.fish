# Load cargo environment
if test -e "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
else if test -e "$HOME/.cargo/env"
    if type -q bass
        bass source "$HOME/.cargo/env"
    end
end
