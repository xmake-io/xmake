
## ENVIRONMENT MANAGEMENT ######################################################

<#
    .SYNOPSIS
        Activates a xrepo environment based on your current project.

    .EXAMPLE
        Enter-XrepoEnvironment
#>
function Enter-XrepoEnvironment {
    [CmdletBinding()]
    param();

    begin {
        $script:xrepoOldEnvs = (Get-ChildItem -Path Env:);
        $xrepoPrompt = (& $Env:XMAKE_EXE lua private.xrepo env --info prompt | Out-String);
        $activateCommand = (& $Env:XMAKE_EXE lua private.xrepo env --info script.powershell | Out-String);

        Write-Verbose "[xrepo env script.powershell]`n$activateCommand";
        Invoke-Expression -Command $activateCommand;

        $Env:XMAKE_PROMPT_MODIFIER = $xrepoPrompt.Trim() + " ";
    }
    process {}
    end {}
}


<#
    .SYNOPSIS
        Deactivates the current xrepo environment, if any.

    .EXAMPLE
        Exit-XrepoEnvironment
#>
function Exit-XrepoEnvironment {
    [CmdletBinding()]
    param();

    begin {
        # Write-Host $script:xrepoOldEnvs;
        ForEach ($p in $script:xrepoOldEnvs) {
            [Environment]::SetEnvironmentVariable($p.Name, $p.Value);
        }
        $Env:XMAKE_PROMPT_MODIFIER = "";
    }
    process {}
    end {}
}


if (Test-Path Function:\prompt) {
    Rename-Item Function:\prompt XrepoPromptBackup
} else {
    function XrepoPromptBackup() {
        # Restore a basic prompt if the definition is missing.
        "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    }
}


<#
    .SYNOPSIS
        Modifies the current prompt to show the current xmake project.

    .EXAMPLE
        Add-XrepoEnvironmentToPrompt

        Causes the current session's prompt to display the current xmake project name.
#>
function Add-XrepoEnvironmentToPrompt() {
    function global:prompt() {
        if ($Env:XMAKE_PROMPT_MODIFIER) {
            $Env:XMAKE_PROMPT_MODIFIER | Write-Host -NoNewline
        }
        XrepoPromptBackup;
    }
}


## EXPORTS ###################################################################

Export-ModuleMember `
    -Alias * `
    -Function `
        Add-XrepoEnvironmentToPrompt, `
        Enter-XrepoEnvironment, `
        Exit-XrepoEnvironment, `
        prompt
