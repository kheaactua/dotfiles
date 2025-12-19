function detect_version_code -d "Detect OS version codename from /etc/os-release"
    if test -f /etc/os-release
        grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"'
    end
end
