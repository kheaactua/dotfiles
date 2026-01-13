# Native fish PATH setup (replaces .pathrc for better performance)
# Bass overhead: ~1.2s per shell startup. Fish native: <0.01s

# Fish helper functions for PATH manipulation
function path_append
    set -l dir $argv[1]
    test -e "$dir"; and fish_add_path --path --append $dir
end

function path_prepend
    set -l dir $argv[1]
    test -e "$dir"; and fish_add_path --path --prepend $dir
end

# Common user paths (in reverse priority order - last one wins)
path_prepend "$HOME/.config/autorandr"
path_prepend "$HOME/bin"
path_prepend "$HOME/utils"
path_prepend "$HOME/.composer/vendor/bin"
path_prepend "$HOME/.rvm/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.fzf/bin"
path_prepend "$HOME/.pyenv/bin"
path_prepend "$HOME/utils/bin"
path_prepend "$HOME/.cargo/bin"
path_prepend "$HOME/go/bin"
path_prepend "$HOME/platform-tools"
path_prepend "$HOME/.local/share/bob/nvim-bin"
path_prepend "$HOME/.npm_packages/bin"

# NVM node installation
if test -e "$HOME/.nvm/versions/node"
    set -l latest_node (command ls -1 "$HOME/.nvm/versions/node" | tail -1)
    if test -n "$latest_node"
        path_prepend "$HOME/.nvm/versions/node/$latest_node/bin"
    end
end

path_append "/var/lib/snapd/bin"
path_append "/snap/bin"
path_append "/usr/local/go/bin"

# If you need to load the original bash .pathrc, uncomment:
# if test -e "$HOME/.pathrc"; and type -q bass
#     bass source "$HOME/.pathrc"
# end
