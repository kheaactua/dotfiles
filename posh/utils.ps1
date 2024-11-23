# Misc functions
Write-Host "Loading misc functions" -ForegroundColor Yellow

# Helper function to set location to the User Profile directory
function cuserprofile { Set-Location ~ }
Set-Alias ~ cuserprofile -Option AllScope

# https://github.com/joonro/Get-ChildItemColor
# https://www.powershellgallery.com/packages/Get-ChildItemColor/
# verify this is the console and not the ISE
Import-Module Get-ChildItemColor
Set-Alias ls Get-ChildItemColor -option AllScope

# Linux `which`
New-Alias which Get-Command

# Other aliases
New-Alias wget Invoke-WebRequest

# https://github.com/dahlbyk/posh-sshell
# Import-Module -Name posh-sshell
# Import-Module -Name Posh-SSH
# Import-Module -Name ThreadJob

# Get info about whatever process is using a specified port
function Get-PortUser($port) { Get-Process -Id (Get-NetTCPConnection -LocalPort $port).OwningProcess; }

# Slow, but it saves me from going to github to getthe newest release
# https://superuser.com/a/1625888/184123
function Update-PWSH {
	Invoke-Expression -Command "& { $(Invoke-RestMethod -Uri 'https://aka.ms/install-powershell.ps1') } -UseMSI"
}

function ln($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target
}

# vim: ts=4 sw=4 sts=0 noexpandtab ff=dos ft=ps1 :
