& {

Function myExit($code){
    if($code -is [int] -and $code -ne 0){
        throw $Error[0]
    }else{
        break
    }
}

Function writeErrorTip($msg){
    Write-Host $msg -BackgroundColor Red -ForegroundColor White
}

Function writeLogoLine($msg){
    Write-Host $msg -BackgroundColor White -ForegroundColor DarkBlue
}

Function Get-AppVeyorArtifacts{
    param(
        [parameter(Mandatory = $true)]
        [string]$Account,
        [parameter(Mandatory = $true)]
        [string]$Project,
        [parameter(Mandatory = $true)]
        [string]$DownloadDirectory)
    $apiUrl = 'https://ci.appveyor.com/api'
    $headers = @{
        'Content-type' = 'application/json'
    }
    $obj = Invoke-RestMethod -Method Get -Uri "$apiUrl/projects/$Account/$Project" -Headers $headers
    $jobId = $null
    if([environment]::Is64BitOperatingSystem){
        $jobId = 1
    }else{
        $jobId = 0
    }
    $jobId = $obj.build.jobs[$jobId].jobId
    $artifacts = Invoke-RestMethod -Method Get -Uri "$apiUrl/buildjobs/$jobId/artifacts" -Headers $headers
    $artifactFileName = $artifacts[0].fileName
    $localArtifactPath = "$DownloadDirectory\$artifactFileName"
    Invoke-RestMethod -Method Get -Uri "$apiUrl/buildjobs/$jobId/artifacts/$artifactFileName" -OutFile $localArtifactPath
}

writeLogoLine '                         _                      '
writeLogoLine '    __  ___ __  __  __ _| | ______              '
writeLogoLine '    \ \/ / |  \/  |/ _  | |/ / __ \             '
writeLogoLine '     >  <  | \__/ | /_| |   <  ___/             '
writeLogoLine '    /_/\_\_|_|  |_|\__ \|_|\_\____| getter      '
writeLogoLine '                                                '
writeLogoLine '                                                '

if($PSVersionTable.PSVersion.Major -lt 5){
    writeErrorTip 'Sorry but PowerShell v5+ is required'
    throw 'PowerShell''s version too low'
}

try{
    $installdir="$HOME\xmake"
    try{Remove-Item -Recurse -Force $installdir}catch{}
    New-Item $installdir -ItemType directory
    try{
        Get-AppVeyorArtifacts waruqi xmake $installdir
    }catch{
        Get-AppVeyorArtifacts TitanSnow "xmake-90ua9" $installdir
    }
    if($branch -eq $null){ $branch='master' }
    Invoke-Webrequest "https://github.com/tboox/xmake/archive/$branch.zip" -OutFile "$installdir\temp.zip"
    Expand-Archive "$installdir\temp.zip" "$installdir\temp" -Force
    Move-Item "$installdir\temp\xmake-$branch\xmake\*" $installdir -Recurse
    Remove-Item "$installdir\temp","$installdir\temp.zip" -Recurse -Force
    $env:Path+=";$installdir"
    [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path",[System.EnvironmentVariableTarget]::User)+";$installdir",[System.EnvironmentVariableTarget]::User)    # this step is optional because installer writes path to regedit
    xmake --version
}catch{
    writeErrorTip 'Error!'
    myExit 1
}

}
