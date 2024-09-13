#!/usr/bin/env pwsh
#Requires -version 5

param (
    [string]$archivefile,
    [string]$outputdir
)

& {
    function writeErrorTip($msg) {
        Write-Host $msg -BackgroundColor Red -ForegroundColor White
    }

    function unzip {
        try {
            Expand-Archive -Path $archivefile -DestinationPath $outputdir
        } catch {
            writeErrorTip 'Unzip failed!'
            throw
        }
    }

    unzip
}
