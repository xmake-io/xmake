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
    $LastRelease = "v3.0.6"
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
        writeErrorTip '(Use curl) "curl -fsSL https://xmake.io/shget.text | bash"'
        writeErrorTip 'or'
        writeErrorTip '(Use wget) "wget https://xmake.io/shget.text -O - | bash"'
        throw 'Unsupported platform'
    }

    $temppath = ([System.IO.Path]::GetTempPath(), $env:TMP, $env:TEMP, "$(Get-Location)" -ne $null)[0]
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
        $x64arch = @('AMD64', 'IA64')
        $arch = if ($env:PROCESSOR_ARCHITECTURE -in $x64arch -or $env:PROCESSOR_ARCHITEW6432 -in $x64arch) { 'x64' } else { 'x86' }
        $winarch = if ($env:PROCESSOR_ARCHITECTURE -in $x64arch -or $env:PROCESSOR_ARCHITEW6432 -in $x64arch) { 'win64' } else { 'win32' }
        if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') {
            Write-Host "Unsupported host architecture detected: ARM64."
        }
        $url = if ($v -is [version]) {
            "https://github.com/xmake-io/xmake/releases/download/v$v/xmake-v$v.$winarch.exe"
        } else {
            "https://github.com/xmake-io/xmake/releases/download/$LastRelease/xmake-$v.$winarch.exe"
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
        # TODO: add --global --user choice
        Write-Host "Tab completion service"
        try {
            xmake update --integrate
        } catch {
            writeErrorTip "Failed to register tab completion!"
            writeErrorTip 'Please try "xmake update --integrate" to register manually.'
            return
        }
        Write-Host "Tab completion installed"
    }

    checkTempAccess
    xmakeInstall

    if (-not $env:CI) {
        registerTabCompletion
    } else {
        Write-Host "Tab completion registration has been skipped for CI"
    }

}
