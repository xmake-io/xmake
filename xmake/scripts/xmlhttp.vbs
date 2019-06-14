url = WScript.Arguments(0)
destfile = WScript.Arguments(1)

Set ServerXMLHTTP = CreateObject("MSXML2.ServerXMLHTTP")
ServerXMLHTTP.Open "GET", WScript.Arguments(0), false
ServerXMLHTTP.Send

Set Fs = CreateObject("Scripting.FileSystemObject")

exists = Fs.FileExists(destfile)
If exists Then
    Fs.DeleteFile destfile
End If

set BinStream = CreateObject("ADODB.Stream")
BinStream.Type = 1
BinStream.Open
BinStream.Write ServerXMLHTTP.ResponseBody
BinStream.SaveToFile destfile