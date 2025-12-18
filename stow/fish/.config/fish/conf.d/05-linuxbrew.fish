# Linuxbrew setup
if test -e "$HOME/.linuxbrew"
    set -gx LINUXBREWHOME "$HOME/.linuxbrew"
else if test -e /home/linuxbrew/.linuxbrew
    set -gx LINUXBREWHOME /home/linuxbrew/.linuxbrew
end

if set -q LINUXBREWHOME
    fish_add_path --path --prepend "$LINUXBREWHOME/bin"
    fish_add_path --path --prepend "$LINUXBREWHOME/sbin"
    set -gx MANPATH "$LINUXBREWHOME/share/man" $MANPATH
    set -gx INFOPATH "$LINUXBREWHOME/share/info" $INFOPATH
end
