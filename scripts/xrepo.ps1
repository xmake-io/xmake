$script:SCRIPT_PATH = $myinvocation.mycommand.path
$script:BASE_DIR = Split-Path $SCRIPT_PATH -Parent
$Env:XMAKE_EXE = Join-Path $BASE_DIR xmake.exe


if ($Args.Count -eq 0) {
    # No args, just call the underlying conda executable.
    & $Env:XMAKE_EXE lua private.xrepo;
} else {
    $Command = $Args[0];
    if (($Command -eq "env") -and ($Args.Count -ge 2)) {
        switch ($Args[1]) {
            "shell" {
                if (-not (Test-Path 'Env:XMAKE_ROOT')) {
                    $Env:XMAKE_ROOT = $BASE_DIR;
                    Import-Module "$Env:XMAKE_ROOT\scripts\xrepo-hook.psm1";
                    Add-XrepoEnvironmentToPrompt;
                }
                if ((Test-Path 'Env:XMAKE_PROMPT_MODIFIER') -and ($Env:XMAKE_PROMPT_MODIFIER -ne "")) {
                    Exit-XrepoEnvironment;
                }
                Enter-XrepoEnvironment;
                return;
            }
            "deactivate" {
                Exit-XrepoEnvironment;
                return;
            }
        }
    }

    $OtherArgs = @();
    & $Env:XMAKE_EXE lua private.xrepo $Command @OtherArgs;
}
