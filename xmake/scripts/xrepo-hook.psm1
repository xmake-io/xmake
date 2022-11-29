
## ENVIRONMENT MANAGEMENT ######################################################

<#
    .SYNOPSIS
        Enter a xrepo environment based on your current project.

    .EXAMPLE
        Enter-XrepoEnvironment
#>
function Enter-XrepoEnvironment {
    [CmdletBinding()]
    param(
        [string]$bnd
    );

    begin {
        $script:xrepoOldEnvs = (Get-ChildItem -Path Env:);

        if (-not $bnd) {
            & $Env:XMAKE_EXE lua private.xrepo.action.env.info config;
            if (-not $?) {
                Exit 1;
            }

            $xmakeColorTermBackup, $Env:XMAKE_COLORTERM = $Env:XMAKE_COLORTERM, "nocolor";
            $xrepoPrompt = (& $Env:XMAKE_EXE lua --quiet private.xrepo.action.env.info prompt | Out-String);
            $Env:XMAKE_COLORTERM = $xmakeColorTermBackup;
            if (-not $xrepoPrompt.StartsWith("[")) {
                Write-Host "error: xmake.lua not found!";
                Exit 1;
            }

            $activateCommand = (& $Env:XMAKE_EXE lua --quiet private.xrepo.action.env.info script.powershell | Out-String);
        } else {
            & $Env:XMAKE_EXE lua private.xrepo.action.env.info config $bnd;
            if (-not $?) {
                Exit 1;
            }

            $xmakeColorTermBackup, $Env:XMAKE_COLORTERM = $Env:XMAKE_COLORTERM, "nocolor";
            $xrepoPrompt = (& $Env:XMAKE_EXE lua --quiet private.xrepo.action.env.info prompt $bnd | Out-String);
            $Env:XMAKE_COLORTERM = $xmakeColorTermBackup;
            if (-not $xrepoPrompt.StartsWith("[")) {
                Write-Host "error: invalid environment!";
                Exit 1;
            }

            $activateCommand = (& $Env:XMAKE_EXE lua --quiet private.xrepo.action.env.info script.powershell $bnd | Out-String);
        }

        Write-Verbose "[xrepo env script.powershell]`n$activateCommand";
        Invoke-Expression -Command $activateCommand;

        $Env:XMAKE_PROMPT_MODIFIER = $xrepoPrompt.Trim() + " ";
    }
    process {}
    end {}
}


<#
    .SYNOPSIS
        Exit the current xrepo environment, if any.

    .EXAMPLE
        Exit-XrepoEnvironment
#>
function Exit-XrepoEnvironment {
    [CmdletBinding()]
    param();

    begin {
        ForEach ($p in (Get-ChildItem Env:)) {
            [Environment]::SetEnvironmentVariable($p.Name, $Null);
        }
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
