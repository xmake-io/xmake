# PowerShell parameter completion shim for xmake

Register-ArgumentCompleter -Native -CommandName xmake -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    xmake lua private.utils.complete "$cursorPosition" "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
