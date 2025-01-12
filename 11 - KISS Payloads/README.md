# Source: https://github.com/gustanini/DLL-Hijack-POC/tree/main

### revshell.cpp
- Simple C++ reverse shell, can be used to bypass Windows Defender if we want to get a simple reverse shell from the target.

### newadmin.cpp
DLL that will create a new local admin with the username `amit` and the password `Password123!`. 
- Compile in linux with: `x86_64-w64-mingw32-gcc -shared -o backdoor.dll newadmin.cpp` 
