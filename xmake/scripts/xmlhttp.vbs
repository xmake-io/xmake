url = WScript.Arguments(0)
destfile = WScript.Arguments(1)

Function readFromRegistry (strRegistryKey, strDefault)
    Dim WSHShell, value

    On Error Resume Next
    Set WSHShell = CreateObject("WScript.Shell")
    value = WSHShell.RegRead( strRegistryKey )

    if err.number <> 0 then
        readFromRegistry= strDefault
    else
        readFromRegistry=value
    end if

    set WSHShell = nothing
End Function

Set WinHttp = CreateObject("WinHttp.WinHttpRequest.5.1")
Proxy = readFromRegistry("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ProxyServer", "")
If Proxy <> "" Then
    WScript.Echo "Using proxy: " & Proxy
    WinHttp.SetProxy 2, Proxy
End If
WinHttp.Open "GET", url, false
WinHttp.Option(4) = 13056
If WScript.Arguments.Count >= 3 Then
    WScript.Echo "Using User-Agent: " & WScript.Arguments(2)
    WinHttp.Option(0) = WScript.Arguments(2)
End If
WinHttp.Send

Set Fs = CreateObject("Scripting.FileSystemObject")

exists = Fs.FileExists(destfile)
If exists Then
    Fs.DeleteFile destfile
End If

set BinStream = CreateObject("ADODB.Stream")
BinStream.Type = 1
BinStream.Open
BinStream.Write WinHttp.ResponseBody
BinStream.SaveToFile destfile
