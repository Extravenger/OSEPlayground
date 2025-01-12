### revshell.cpp
Simple C++ reverse shell, can be used to bypass windows defender if we want to get a simple reverse shell.

### newadmin.cpp
Dll that will make a new local admin with the username `amit` and the password `Password123!`.
Compile in linux with: `x86_64-w64-mingw32-gcc -shared -o backdoor.dll newadmin.cpp` 
