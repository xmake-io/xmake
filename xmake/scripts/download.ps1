#!/usr/bin/env pwsh
#Requires -version 5

param (
    [string]$url,
    [string]$outputfile
)

& {
    function writeErrorTip($msg) {
        Write-Host $msg -BackgroundColor Red -ForegroundColor White
    }

    $temppath = ([System.IO.Path]::GetTempPath(), $env:TMP, $env:TEMP, "$(Get-Location)" -ne $null)[0]
    [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

    function download {
        try {
            Invoke-Webrequest $url -OutFile $outputfile -UseBasicParsing
        } catch {
            writeErrorTip 'Download failed!'
            throw
        }
    }

    download
}
