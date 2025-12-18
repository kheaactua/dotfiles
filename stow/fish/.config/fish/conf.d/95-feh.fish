# Set up run-feh function for graphical sessions
if test -n "$DISPLAY"; or test -n "$XDG_SESSION_TYPE"
    function run-feh
        if type -q feh
            feh --randomize --bg-fill ~/Desktop/Backgrounds/*
        end
    end
end
