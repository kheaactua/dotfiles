# Source work-specific fish configurations if they exist
# These come from ~/dotfiles/dotfiles-secret/work/stow/fish-work/.config/fish-work/

# Source all files in ~/.config/fish-work/conf.d/
if test -d $HOME/.config/fish-work/conf.d
    for file in $HOME/.config/fish-work/conf.d/*.fish
        if test -f $file
            source $file
        end
    end
end

# Add work functions directory to fish_function_path if it exists
if test -d $HOME/.config/fish-work/functions
    set -g fish_function_path $HOME/.config/fish-work/functions $fish_function_path
end
