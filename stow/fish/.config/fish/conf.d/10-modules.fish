# Initialize environment modules
if test -f /usr/share/modules/init/fish
    source /usr/share/modules/init/fish
else
    echo "Environment modules not installed"
end

# Add user modulefiles directory if it exists
if type -q module; and test -e "$HOME/.modulefiles"
    module use "$HOME/.modulefiles"
end
