## newadmin.cpp
Source: https://github.com/gustanini/DLL-Hijack-POC/tree/main 

DLL that will create a new local admin with the username `amit` and the password `Password123!`. 
- Compile in linux with: `x86_64-w64-mingw32-gcc -shared -o backdoor.dll newadmin.cpp` 

## newadmin.c
Source: https://github.com/newsoft/adduser/blob/master/adduser.c

DLL that will create a new local admin with the username `amit` and the password `Password123!`.
- 32bit Compilation: `i686-w64-mingw32-gcc -shared -oadduser32.dll adduser.c -lnetapi32`
- 64bit Compilation: `x86_64-w64-mingw32-gcc -shared -oadduser64.dll adduser.c -lnetapi32`
