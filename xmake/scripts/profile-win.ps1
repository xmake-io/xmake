# PowerShell parameter completion for xmake
Register-ArgumentCompleter -Native -CommandName xmake -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    $complete = "$wordToComplete"
    if (-not $commandName) {
        $complete = $complete + " "
    }
    $oldenv = $env:XMAKE_SKIP_HISTORY
    $env:XMAKE_SKIP_HISTORY = 1
    xmake lua --root private.utils.complete "0" "nospace" "$complete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
    $env:XMAKE_SKIP_HISTORY = $oldenv
}