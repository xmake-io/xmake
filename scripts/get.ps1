# xmake getter
# usage: (in powershell)
#  Invoke-Expression (Invoke-Webrequest <my location> -UseBasicParsing).Content

param (
    [string]$branch = "master", 
    [string]$version = "v2.2.6",
    [string]$installdir = $(Join-Path $(if($HOME) { $HOME } else { "C:\" }) 'xmake')
)

function myExit($code) {
    if ($code -is [int] -and $code -ne 0) {
        throw $Error[0]
    } else {
        break
    }
}

function writeErrorTip($msg) {
    Write-Host $msg -BackgroundColor Red -ForegroundColor White
}

function writeLogoLine($msg) {
    Write-Host $msg -BackgroundColor White -ForegroundColor DarkBlue
}

if (-not $env:CI) {
    writeLogoLine '                         _                      '
    writeLogoLine '    __  ___ __  __  __ _| | ______              '
    writeLogoLine '    \ \/ / |  \/  |/ _  | |/ / __ \             '
    writeLogoLine '     >  <  | \__/ | /_| |   <  ___/             '
    writeLogoLine '    /_/\_\_|_|  |_|\__ \|_|\_\____| getter      '
    writeLogoLine '                                                '
    writeLogoLine '                                                '
}

if ($PSVersionTable.PSVersion.Major -lt 5) {
    writeErrorTip 'Sorry but PowerShell v5+ is required'
    throw 'PowerShell''s version too low'
}
$temppath = ($env:TMP, $env:TEMP, '.' -ne $null)[0]
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

function checkTempAccess {
    $outfile = Join-Path $temppath "$pid.tmp"
    try {
        Write-Output $pid | Out-File -FilePath $outfile
        Remove-Item $outfile
    } catch {
        writeErrorTip 'Cannot write to temp path'
        writeErrorTip 'Please set environment var "TMP" to another path'
        throw
    }
}

function xmakeInstall {
    $outfile = Join-Path $temppath "$pid-xmake-installer.exe"
    Write-Host "Start downloading https://github.com/xmake-io/xmake/releases/download/$version/xmake-$branch.exe .."
    try {
        Invoke-Webrequest "https://github.com/xmake-io/xmake/releases/download/$version/xmake-$branch.exe" -OutFile $outfile
    } catch {
        writeErrorTip 'Download failed!'
        writeErrorTip 'Check your network or... the news of S3 break'
        throw
    }
    Write-Host 'Start installation... Hope your antivirus doesn''t trouble'
    Write-Host "Install to $installdir"
    try {
        Start-Process -FilePath $outfile -ArgumentList "/S /D=$installdir" -Wait
    } catch {
        writeErrorTip 'Install failed!'
        writeErrorTip 'Close your antivirus then try again'
        throw
    } finally {
        Remove-Item $outfile -ErrorAction SilentlyContinue
    }
    Write-Host 'Adding to PATH... almost done'
    $env:Path += ";$installdir"
    [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User) + ";$installdir", [System.EnvironmentVariableTarget]::User)    # this step is optional because installer writes path to regedit
    try {
        xmake --version
    } catch {
        writeErrorTip 'Everything is showing installation has finished'
        writeErrorTip 'But xmake could not run... Why?'
        throw
    }
}

function xmakeSelfBuild {
    Write-Host "Pulling xmake from branch $branch"
    $outfile = Join-Path $temppath "$pid-xmake-repo.zip"
    try {
        Invoke-Webrequest "https://github.com/xmake-io/xmake/archive/$branch.zip" -OutFile $outfile
    } catch {
        writeErrorTip 'Pull Failed!'
        writeErrorTip 'xmake is now available but may not be newest'
        throw
    }
    Write-Host 'Expanding archive...'
    $oldpwd = Get-Location
    $repodir = New-Item -Path $temppath -Name "$pid-xmake-repo" -ItemType Directory -Force
    try {
        Expand-Archive -Path $outfile -DestinationPath $repodir -Force
        Write-Host 'Self-building...'
        Set-Location $(Join-Path $repodir "\xmake-$branch\core")
        xmake
        Write-Host 'Copying new files...'
        Copy-Item -Path '.\build\xmake.exe' -Destination $installdir -Force
        Set-Location '..\xmake'
        Copy-Item -Path * -Destination $installdir -Recurse -Force
        xmake --version
    } catch {
        writeErrorTip 'Update Failed!'
        writeErrorTip 'xmake is now available but may not be newest'
        throw
    } finally {
        Set-Location $oldpwd -ErrorAction SilentlyContinue
        Remove-Item $outfile -ErrorAction SilentlyContinue
        Remove-Item $repodir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function registerTabCompletion {

    function writeDataToFile($file) {
        $encoding = [text.encoding]::UTF8
        if (Test-Path $file -PathType Leaf) {
            #Create a stream reader to get the file's encoding and contents.
            $sr = New-Object System.IO.StreamReader($file, $true)
            [char[]] $buffer = new-object char[] 3
            $sr.Read($buffer, 0, 3) | Out-Null
            $encoding = $sr.CurrentEncoding
            $sr.Close() | Out-Null 

            if ($(Get-Content $file) -imatch "Register-ArgumentCompleter -Native -CommandName xmake -ScriptBlock") {
                Write-Host "Seems the tab completion of xmake has installed here..."
                return
            }
        }

        try {
            [IO.File]::AppendAllText($file, "`n", $encoding)
        } catch {
            writeErrorTip "Failed to append to profile!"
            writeErrorTip "Please try again as administrator"
            return
        }
        try {
            $content = (Invoke-Webrequest 'https://raw.githubusercontent.com/xmake-io/xmake/master/scripts/register-completions.ps1' -UseBasicParsing).Content
        } catch {
            writeErrorTip 'Download failed!'
            writeErrorTip 'Check your network or... the news of S3 break'
            return
        }
        [IO.File]::AppendAllText($file, $content, $encoding)
        [IO.File]::AppendAllText($file, "`n", $encoding)
    }
    $message = 'Tab completion service'
    $question = 'Would you like to install tab completion service of xmake to your profile?'

    $choices = @(
        (New-Object Management.Automation.Host.ChoiceDescription -ArgumentList @(
                'For &all users',
                "Install for all users, writes to $($PROFILE.AllUsersAllHosts), admin privilege is needed.")),
        (New-Object Management.Automation.Host.ChoiceDescription -ArgumentList @(
                'Just for &me',
                "Install for current user, writes to $($PROFILE.CurrentUserAllHosts).")),
        (New-Object Management.Automation.Host.ChoiceDescription -ArgumentList @(
                'Just for this &host',
                "Install for current user current host, writes to $($PROFILE.CurrentUserCurrentHost).")),
        (New-Object Management.Automation.Host.ChoiceDescription -ArgumentList @(
                '&No',
                "Do not install xmake's tab completion service."))
    )
    switch ($Host.UI.PromptForChoice($message, $question, $choices, 1)) {
        0 { writeDataToFile($PROFILE.AllUsersAllHosts) }
        1 { writeDataToFile($PROFILE.CurrentUserAllHosts) }
        2 { writeDataToFile($PROFILE.CurrentUserCurrentHost) }
    }
}

try {
    checkTempAccess
    xmakeInstall  
} catch {
    myExit 1
}


if (-not $env:CI) {
    try {
        xmakeSelfBuild
    } catch { } # continue
    registerTabCompletion
} else {
    Write-Host "Self bulid and tab completion registration has been skipped for CI"
}

