# Qt/GTK portal configuration for better kitty integration
# Gemini suggested this to get kitty working better with file pickers, etc.
if test -n "$DISPLAY"; or test -n "$XDG_SESSION_TYPE"
    set -gx QT_QPA_PLATFORMTHEME xdgdesktopportal
    set -gx GTK_USE_PORTAL 1
end
