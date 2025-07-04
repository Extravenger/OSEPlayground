## Constrained Language Mode (CLM) Bypass

- The `CLM-Bypass.xml` source file enables bypassing Constrained Language Mode (CLM) to achieve FullLanguage mode within the same session. To utilize, transfer the file to the target system and execute:
  - `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe CLM-Bypass.xml`

## Process Hollowing

- The `hollow.xml` file facilitates process hollowing, offering a stable method capable of executing both 32-bit and 64-bit shellcode while evading Windows Defender detection. To deploy, transfer the file to the target system and execute:
  - `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe hollow.xml`
  - **Note**: The shellcode is XOR-encrypted with the key `0xfa`.

## Process Injection

- The `processInjection.xml` file supports process injection, providing a reliable mechanism for executing both 32-bit and 64-bit shellcode while bypassing Windows Defender. To implement, transfer the file to the target system and execute:
  - `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe inject.xml`
  - **Note**: The shellcode is XOR-encrypted with the key `0xfa`.

## Shellcode Execution

- The `shellcodeRunner.xml` file is designed to inject and execute shellcode within the current process. To use, transfer the file to the target system and execute:
  - `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe shellcodeRunner.xml`
  - **Note**: The shellcode is XOR-encrypted with the key `0xfa`.
