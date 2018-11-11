Set UAC = CreateObject("Shell.Application")
Set Shell = CreateObject("WScript.Shell")
If WScript.Arguments.count < 1 Then
    WScript.echo "Help: sudo <command> [args]"
ElseIf WScript.Arguments.count = 1 Then
    UAC.ShellExecute WScript.arguments(0), "", "", "runas", 1
Else
    Dim ucCount
    Dim args
    args = NULL
    For ucCount = 1 To (WScript.Arguments.count - 1) Step 1
        args = args & " " & WScript.Arguments(ucCount)
    Next
    UAC.ShellExecute WScript.arguments(0), args, "", "runas", 5
End If
