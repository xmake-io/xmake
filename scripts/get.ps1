#! /usr/bin/pwsh
#Requires -version 5

# xmake getter
# usage: (in powershell)
#  Invoke-Expression (Invoke-Webrequest <my location> -UseBasicParsing).Content

param (
    [string]$branch = "master",
    [string]$installdir = ""
)

function writeErrorTip($msg) {
    Write-Host $msg -BackgroundColor Red -ForegroundColor White
}

if (-not $env:CI) {
    $logo = @(
        '                         _                      '
        '    __  ___ __  __  __ _| | ______              '
        '    \ \/ / |  \/  |/ _  | |/ / __ \             '
        '     >  <  | \__/ | /_| |   <  ___/             '
        '    /_/\_\_|_|  |_|\__ \|_|\_\____| getter      '
        '                                                '
        '                                                ')
    Write-Host $([string]::Join("`n", $logo)) -BackgroundColor White -ForegroundColor DarkBlue
}

if ($IsLinux -or $IsMacOS) {
    writeErrorTip 'Install on *nix is not supported, try ' 
    writeErrorTip '(Use curl) "bash <(curl -fsSL https://raw.githubusercontent.com/xmake-io/xmake/master/scripts/get.sh)"'
    writeErrorTip 'or' 
    writeErrorTip '(Use wget) "bash <(wget https://raw.githubusercontent.com/xmake-io/xmake/master/scripts/get.sh -O -)"'
    throw 'Unsupported platform'
}

$temppath = ($env:TMP, $env:TEMP, '.' -ne $null)[0]
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

if ($null -eq $installdir -or $installdir -match '^\s*$') {
    $installdir = & {
        # Install to old xmake path
        $oldXmake = Get-Command xmake -CommandType Application -ErrorAction SilentlyContinue
        if ($oldXmake) {
            return Split-Path $oldXmake.Path -Parent
        }
        if ($HOME) {
            return Join-Path $HOME 'xmake'
        }
        if ($env:APPDATA) {
            return Join-Path $env:APPDATA 'xmake'
        }
        if ($env:ProgramFiles) {
            return Join-Path $env:ProgramFiles 'xmake'
        }
        return 'C:\xmake'
    }
}

if ($null -eq $branch -or $branch -match '^\s*$') {
    $branch = 'master'
}

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
    $x64arch = @('AMD64', 'IA64', 'ARM64')
    $arch = if ($env:PROCESSOR_ARCHITECTURE -in $x64arch -or $env:PROCESSOR_ARCHITEW6432 -in $x64arch) { 'x64' } else { 'x86' }
    $url = "https://ci.appveyor.com/api/projects/waruqi/xmake/artifacts/xmake-installer.exe?branch=$branch&pr=false&job=Image%3A+Visual+Studio+2017%3B+Platform%3A+$arch"
    Write-Host "Start downloading $url .."
    try {
        Invoke-Webrequest $url -OutFile $outfile -UseBasicParsing
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
                Write-Host "Seems the tab completion of xmake has installed here... skipped"
                return
            }
        }

        try {
            New-Item $(Split-Path $file -Parent) -ItemType Directory -Force | Out-Null
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
        . $file
        Write-Host "Tab completion installed"
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

checkTempAccess
xmakeInstall

if (-not $env:CI) {
    registerTabCompletion
} else {
    Write-Host "Tab completion registration has been skipped for CI"
}

