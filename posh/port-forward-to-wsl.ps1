function Update-WslSshPortForwarding {
    <#
    .SYNOPSIS
        Updates the netsh port forwarding rule to allow SSH access to a WSL2 instance.

    .DESCRIPTION
        This function automatically detects the current IP address of a specified WSL2 distribution,
        removes any existing netsh port forwarding rules for a given Windows listen port,
        and then adds a new rule to forward traffic from the Windows host to the WSL2 instance.
        This is essential for accessing WSL2 services (like SSH) from other machines on the network,
        as WSL2's internal IP addresses are dynamic.

    .PARAMETER WslDistroName
        The exact name of your WSL2 distribution (e.g., 'ArchLinux', 'Ubuntu', 'Debian').
        You can find this by running 'wsl -l -v' in PowerShell.

    .PARAMETER WindowsListenPort
        The port on your Windows machine that will listen for incoming connections.
        This is the port you will use to connect from other machines (e.g., 2222).
        Default is 2222.

    .PARAMETER WslSshPort
        The port your SSH server inside the WSL2 distribution is listening on.
        Default is 22 (the standard SSH port).

    .PARAMETER WindowsListenAddress
        The IP address on your Windows machine that will listen for connections.
        '0.0.0.0' means it will listen on all available network interfaces.
        You can specify a specific IP (e.g., '192.168.1.100') if preferred.
        Default is '0.0.0.0'.

    .NOTES
        - This function must be run with Administrator privileges.
        - The WSL2 distribution must be running for its IP address to be detected.
        - Ensure your Windows Firewall allows incoming connections on the specified WindowsListenPort.

    .EXAMPLE
        Update-WslSshPortForwarding -WslDistroName "ArchLinux" -WindowsListenPort 2222 -WslSshPort 22

    .EXAMPLE
        # Using default ports, just specifying the distro name
        Update-WslSshPortForwarding -WslDistroName "Ubuntu"

    .EXAMPLE
        # Running the function and pausing for review (for testing)
        Update-WslSshPortForwarding -WslDistroName "ArchLinux"
        Read-Host "Press Enter to continue..."
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$WslDistroName,

        [int]$WindowsListenPort = 2222,
        [int]$WslSshPort = 22,
        [string]$WindowsListenAddress = "0.0.0.0"
    )

    # Ensure the script is running with Administrator privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This function must be run with Administrator privileges."
        Write-Error "Please run PowerShell as an Administrator and try again."
        return
    }

    Write-Host "--- Starting WSL SSH Port Forwarding Update ---" -ForegroundColor Cyan
    Write-Host "Distro: $WslDistroName, Windows Port: $WindowsListenPort, WSL Port: $WslSshPort" -ForegroundColor DarkCyan

    # --- Get WSL IP Address ---
    Write-Host "Detecting WSL IP address for distro '$WslDistroName'..." -ForegroundColor Yellow
    $wslIp = $null
    try {
        # Get the IP address of the specified WSL distro using a robust regex pattern
        $wslIpLines = wsl -d $WslDistroName -e ip -4 addr show eth0 2>&1
        foreach ($line in $wslIpLines) {
            if ($line -match '^\s*inet\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/\d+') {
                $wslIp = $Matches[1]
                break
            }
        }

        if ($wslIp) {
            Write-Host "Detected WSL IP: $wslIp" -ForegroundColor Green
        } else {
            Write-Error "Could not find IP address for WSL distro '$WslDistroName'. Is the distro running and accessible?"
            Write-Error "Output from 'wsl -d $WslDistroName -e ip -4 addr show eth0':"
            $wslIpLines | ForEach-Object { Write-Error $_ }
            return # Exit the function
        }
    } catch {
        Write-Error "Error getting WSL IP: $($_.Exception.Message)"
        return # Exit the function
    }

    # --- Remove Existing Port Proxy Rules ---
    Write-Host "Removing any existing netsh portproxy rules for port $WindowsListenPort..." -ForegroundColor Yellow
    try {
        # Delete v4tov4 rule
        netsh interface portproxy delete v4tov4 listenport=$WindowsListenPort listenaddress=$WindowsListenAddress | Out-Null
        # Delete v4tov6 rule (just in case, if you ever use IPv6 or mixed rules)
        netsh interface portproxy delete v4tov6 listenport=$WindowsListenPort listenaddress=$WindowsListenAddress | Out-Null
        Write-Host "Existing rules for $WindowsListenPort removed (if any)." -ForegroundColor Green
    } catch {
        Write-Warning "No existing rules found or error deleting them. $($_.Exception.Message)"
    }

    # --- Add New Port Proxy Rule ---
    Write-Host "Adding new netsh portproxy rule: $WindowsListenAddress:$WindowsListenPort -> $wslIp:$WslSshPort" -ForegroundColor Yellow
    try {
        netsh interface portproxy add v4tov4 `
            listenport=$WindowsListenPort `
            listenaddress=$WindowsListenAddress `
            connectport=$WslSshPort `
            connectaddress=$wslIp
        Write-Host "New rule added successfully." -ForegroundColor Green
    } catch {
        Write-Error "Error adding new rule: $($_.Exception.Message)"
        return # Exit the function
    }

    # --- Verify Rules (Optional) ---
    Write-Host "Current netsh portproxy rules:" -ForegroundColor DarkCyan
    netsh interface portproxy show all

    Write-Host "--- WSL SSH Port Forwarding Update Completed ---" -ForegroundColor Cyan
}

Update-WslSshPortForwarding -WslDistroName archlinux