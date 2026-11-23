function Get-WslIpAddress {
    <#
    .SYNOPSIS
        Retrieves the current IP address of a specified WSL2 distribution.

    .DESCRIPTION
        This function executes a command inside the specified WSL2 distribution
        to get its IPv4 address for the 'eth0' interface. It then parses the
        output to extract just the IP address string.

    .PARAMETER WslDistroName
        The exact name of your WSL2 distribution (e.g., 'ArchLinux', 'Ubuntu', 'Debian').
        You can find this by running 'wsl -l -v' in PowerShell.

    .NOTES
        - The specified WSL2 distribution must be running for its IP address to be detected.
        - Returns $null if the IP address cannot be found or an error occurs.

    .EXAMPLE
        Get-WslIpAddress -WslDistroName "ArchLinux"
        # Returns: "172.20.153.243" (or the current IP)

    .EXAMPLE
        $wslIp = Get-WslIpAddress -WslDistroName "Ubuntu"
        if ($wslIp) {
            Write-Host "Ubuntu's IP address is: $wslIp"
        } else {
            Write-Host "Could not get Ubuntu's IP address."
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$WslDistroName
    )

    Write-Verbose "Attempting to get IP for WSL distro: $WslDistroName"

    $wslIp = $null
    try {
        # Execute 'ip -4 addr show eth0' inside the WSL distro
        # 2>&1 redirects stderr to stdout, so we capture error messages too
        $wslIpLines = wsl -d $WslDistroName -e ip -4 addr show eth0 2>&1

        # Iterate through each line of output to find the IP address
        foreach ($line in $wslIpLines) {
            # Regex to match 'inet ' followed by an IPv4 address and capture the IP
            if ($line -match '^\s*inet\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/\d+') {
                # $Matches[1] contains the content of the first capturing group (the IP address)
                $wslIp = $Matches[1]
                Write-Verbose "Found IP: $wslIp"
                break # Stop searching once the IP is found
            }
        }

        if (-not $wslIp) {
            Write-Warning "Could not find IP address in output for WSL distro '$WslDistroName'."
            Write-Verbose "WSL Output:"
            $wslIpLines | ForEach-Object { Write-Verbose $_ }
        }

    } catch {
        Write-Error "Error executing command to get WSL IP for '$WslDistroName': $($_.Exception.Message)"
        Write-Verbose "Full error details: $($_.Exception.ToString())"
    }

    # Return the discovered IP address (or $null if not found/error)
    return $wslIp
}
