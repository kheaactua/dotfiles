# Load cargo environment
if test -e "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
else if test -d "$HOME/.cargo/bin"
    # The sh env script only prepends this to PATH; avoid `bass` (spawns python, ~0.45s)
    fish_add_path --prepend --path "$HOME/.cargo/bin"
end
