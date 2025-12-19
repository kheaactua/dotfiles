function detect_platform -d "Detect the platform and architecture"
    set -l uname_o (uname -o 2>/dev/null; or uname -s)
    set -l uname_a (uname -a)
    set -l uname_m (uname -m)
    
    if test "$uname_o" = "Android"; or string match -q "*aarch64*" "$uname_a"
        echo "android_aarch64"
    else if string match -q "*Linux*" "$uname_o"
        echo "linux_$uname_m"
    else
        echo "{$uname_o}_{$uname_m}"
    end
end
