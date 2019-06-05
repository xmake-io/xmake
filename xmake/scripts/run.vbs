Set UAC = CreateObject("Shell.Application")

Const PROCESS = "xmake.exe"

If WScript.Arguments.count < 2 Then
    WScript.echo "Help: run <flag> <command> [args]"
    WScript.echo "    flags:"
    WScript.echo "        N - normal"
    WScript.echo "        A - run as admin"
    WScript.echo "        W - wait xmake to exit"
    WScript.echo "        You should use 'N' if no speical flags needed"
    WScript.echo "    e.g.:  run WA xmake-install.exe /Q"
Else
    Dim flags
    Dim program
    flags = UCase(WScript.arguments(0))
    program = WScript.arguments(1)

    Dim verb
    Dim wait
    If InStr(flags, "A") <> 0 Then
        verb = "runas"
    Else
        verb = "open"
    End If

    If InStr(flags, "W") <> 0 Then
        Dim counter
        counter = 0
        Dim sQuery 
        sQuery = "select * from win32_process where name='" & PROCESS & "'"
        Do
            Set SVC = getobject("winmgmts:root\cimv2")
            Set cproc = SVC.execquery(sQuery)
            iniproc = cproc.count
            counter = counter + 1
            If counter >= 20 Then
                WScript.echo "xmake still hasn't exited after 10 seconds, aborting..."
                WScript.quit 1
            End If
            If iniproc <> 0 Then
                WScript.echo "Waiting for xmake to exit..."
                wscript.sleep 500
            End If
        Loop Until iniproc = 0
        
        Set cproc = Nothing
        Set SVC = Nothing
    End If
    
    Dim ucCount
    Dim args
    args = ""
    For ucCount = 2 To (WScript.Arguments.count - 1) Step 1
        Dim carg
        if InStr(WScript.Arguments(ucCount), " ") <> 0 Then
            carg = """" & Replace(WScript.Arguments(ucCount), """", """""") & """"
        ElseIf Len(WScript.Arguments(ucCount)) = 0 Then
            carg = """"""
        Else
            carg = WScript.Arguments(ucCount)
        End If
        args = args & " " & carg
    Next

    UAC.ShellExecute program, args, "", verb, 1
End If
