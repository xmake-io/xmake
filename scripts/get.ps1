#!/usr/bin/env pwsh
#Requires -version 5

# xmake getter
# usage: (in powershell)
#  Invoke-Expression (Invoke-Webrequest <my location> -UseBasicParsing).Content

param (
    [string]$version = "master",
    [string]$installdir = ""
)

& {
    $ErrorActionPreference = 'Stop'

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
        Write-Host $([string]::Join("`n", $logo)) -ForegroundColor Green
    }

    if ($IsLinux -or $IsMacOS) {
        writeErrorTip 'Install on *nix is not supported, try ' 
        writeErrorTip '(Use curl) "bash <(curl -fsSL https://raw.githubusercontent.com/xmake-io/xmake/master/scripts/get.sh)"'
        writeErrorTip 'or' 
        writeErrorTip '(Use wget) "bash <(wget https://raw.githubusercontent.com/xmake-io/xmake/master/scripts/get.sh -O -)"'
        throw 'Unsupported platform'
    }

    $temppath = ($env:TMP, $env:TEMP, "$(Get-Location)" -ne $null)[0]
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
    $installdir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($installdir)

    if ($null -eq $version -or $version -match '^\s*$') {
        $v = 'master'
    } else {
        $v = $version.Trim()
        if ($v.Contains('.')) {
            $v = [version]::Parse($version)
            $v = New-Object -TypeName version -ArgumentList $v.Major, $v.Minor, $v.Build
        }
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
        $url = if ($v -is [version]) {
            if ($v -gt "2.2.6") {
                "https://ci.appveyor.com/api/projects/waruqi/xmake/artifacts/xmake-installer.exe?tag=v$v&pr=false&job=Image%3A+Visual+Studio+2017%3B+Platform%3A+$arch" 
            } else {
                "https://github.com/xmake-io/xmake/releases/download/v$v/xmake-v$v.exe"
            }
        } else {
            "https://ci.appveyor.com/api/projects/waruqi/xmake/artifacts/xmake-installer.exe?branch=$v&pr=false&job=Image%3A+Visual+Studio+2017%3B+Platform%3A+$arch"
        }
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
            $adminflag = "/NOADMIN "
            try {
                $tempfolder = New-Item "$installdir-$PID-temp" -ItemType Directory
                Remove-Item $tempfolder.FullName
            } catch {
                $adminflag = ""
            }
            Start-Process -FilePath $outfile -ArgumentList "$adminflag/S /D=$installdir" -Wait
        } catch {
            writeErrorTip 'Install failed!'
            writeErrorTip 'Close your antivirus then try again'
            throw
        } finally {
            Remove-Item $outfile -ErrorAction SilentlyContinue
        }
        Write-Host 'Adding to PATH... almost done'
        $env:Path += ";$installdir"
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
            $content = ''
            if (Test-Path $file -PathType Leaf) {
                $content = Get-Content $file -Raw
            }

            try {
                New-Item $(Split-Path $file -Parent) -ItemType Directory -Force | Out-Null
                Set-Content $file $content -NoNewline
            } catch {
                writeErrorTip "Failed to append to profile!"
                writeErrorTip "Please try again as administrator"
                return
            }
            
            if ($content) {
                $content = [System.Text.RegularExpressions.Regex]::Replace($content, "\n*(# PowerShell parameter completion shim for xmake)?\s*Register-ArgumentCompleter -Native -CommandName xmake -ScriptBlock\s*{.+?\n}\s*", "`n", [System.Text.RegularExpressions.RegexOptions]::Singleline) 
            }
            try {
                $appendcontent = (Invoke-Webrequest 'https://raw.githubusercontent.com/xmake-io/xmake/master/scripts/register-completions.ps1' -UseBasicParsing).Content
            } catch {
                writeErrorTip 'Download failed!'
                writeErrorTip 'Check your network or... the news of S3 break'
                return
            }
            Set-Content $file "$content`n$appendcontent" -NoNewline
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

}
