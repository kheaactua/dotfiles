function detect_wsl -d "Detect WSL version (0 if not WSL, 1 or 2 if WSL)"
    set -l wsl_version (uname -r | grep -oP '(?<=WSL)([0-9+])' 2>/dev/null)
    if test -z "$wsl_version"
        echo 0
    else
        echo $wsl_version
    end
end
