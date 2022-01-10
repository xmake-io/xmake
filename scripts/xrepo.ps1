$script:SCRIPT_PATH = $myinvocation.mycommand.path
$script:BASE_DIR = Split-Path $SCRIPT_PATH -Parent
$Env:XMAKE_EXE = Join-Path $BASE_DIR xmake.exe


if ($Args.Count -eq 0) {
    # No args, just call the underlying xmake executable.
    & $Env:XMAKE_EXE lua private.xrepo;
} else {
    $Command = $Args[0];
    if (($Command -eq "env") -and ($Args.Count -ge 2)) {
        switch ($Args[1]) {
            "shell" {
                if (-not (Test-Path 'Env:XMAKE_ROOTDIR')) {
                    $Env:XMAKE_ROOTDIR = $BASE_DIR;
                    Import-Module "$Env:XMAKE_ROOTDIR\scripts\xrepo-hook.psm1";
                    Add-XrepoEnvironmentToPrompt;
                }
                if ((Test-Path 'Env:XMAKE_PROMPT_MODIFIER') -and ($Env:XMAKE_PROMPT_MODIFIER -ne "")) {
                    Exit-XrepoEnvironment;
                }
                Enter-XrepoEnvironment $Null;
                return;
            }
            "quit" {
                Exit-XrepoEnvironment;
                return;
            }
            {$_ -in "-b", "--bind"} {
                if (($Args.Count -ge 4) -and ($Args[3] -eq "shell")) {
                    if (-not (Test-Path 'Env:XMAKE_ROOTDIR')) {
                        $Env:XMAKE_ROOTDIR = $BASE_DIR;
                        Import-Module "$Env:XMAKE_ROOTDIR\scripts\xrepo-hook.psm1";
                        Add-XrepoEnvironmentToPrompt;
                    }
                    if ((Test-Path 'Env:XMAKE_PROMPT_MODIFIER') -and ($Env:XMAKE_PROMPT_MODIFIER -ne "")) {
                        Exit-XrepoEnvironment;
                    }
                    Enter-XrepoEnvironment $Args[2];
                    return;
                }
            }
        }
    }

    & $Env:XMAKE_EXE lua private.xrepo $Args;
}
