function detect_version_id -d "Detect OS version ID from /etc/os-release"
    if test -f /etc/os-release
        grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"'
    end
end
