# xmake getter
# usage: (in powershell)
#  Invoke-Expression (Invoke-Webrequest <my location> -UseBasicParsing).Content

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
$temppath=($env:TMP,$env:TEMP,'.' -ne $null)[0]
$outfile=$temppath+"\$pid-xmake-installer.exe"
try{
    Write-Output "$pid"|Out-File -FilePath "$outfile"
    Remove-Item "$outfile"
}catch{
    writeErrorTip 'Cannot write to temp path'
    writeErrorTip 'Please set environment var "TMP" to another path'
    myExit 1
}
if($ver -eq $null){ $ver='v2.1.5' }
Write-Host 'Start downloading... Hope amazon S3 is not broken again'
try{
    Invoke-Webrequest "https://github.com/tboox/xmake/releases/download/$ver/xmake-$ver.exe" -OutFile "$outfile"
}catch{
    writeErrorTip 'Download failed!'
    writeErrorTip 'Check your network or... the news of S3 break'
    myExit 1
}
Write-Host 'Start installation... Hope your antivirus doesn''t trouble'
$installdir=$HOME+'\xmake'
Write-Host "Install to $installdir"
try{
    Start-Process -FilePath "$outfile" -ArgumentList "/S /D=$installdir" -Wait
}catch{
    Remove-Item "$outfile"
    writeErrorTip 'Install failed!'
    writeErrorTip 'Close your antivirus then try again'
    myExit 1
}
Remove-Item "$outfile"
Write-Host 'Adding to PATH... almost done'
$env:Path+=";$installdir"
[Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path",[System.EnvironmentVariableTarget]::User)+";$installdir",[System.EnvironmentVariableTarget]::User)    # this step is optional because installer writes path to regedit
try{
    xmake --version
}catch{
    writeErrorTip 'Everything is showing installation has finished'
    writeErrorTip 'But xmake could not run... Why?'
    myExit 1
}
if($branch -eq $null){ $branch='master' }
Write-Host "Pulling xmake from branch $branch"
$outfile=$temppath+"\$pid-xmake-repo.zip"
try{
    Invoke-Webrequest "https://github.com/tboox/xmake/archive/$branch.zip" -OutFile "$outfile"
}catch{
    writeErrorTip 'Pull Failed!'
    writeErrorTip 'xmake is now available but may not be newest'
    myExit
}
Write-Host 'Expanding archive...'
New-Item -Path "$temppath" -Name "$pid-xmake-repo" -ItemType "directory" -Force
$oldpwd=$pwd
$repodir=$temppath+"\$pid-xmake-repo"
try{
    Expand-Archive "$outfile" "$repodir" -Force
    Write-Host 'Self-building...'
    Set-Location ($repodir+"\xmake-$branch\core")
    xmake
    Write-Host 'Copying new files...'
    Copy-Item 'build\xmake.exe' "$installdir" -Force
    Set-Location '..\xmake'
    Copy-Item * "$installdir" -Recurse -Force
    xmake --version
}catch{
    writeErrorTip 'Update Failed!'
    writeErrorTip 'xmake is now available but may not be newest'
}finally{
    Set-Location "$oldpwd" -ErrorAction SilentlyContinue
    Remove-Item "$outfile" -ErrorAction SilentlyContinue
    Remove-Item "$repodir" -Recurse -Force -ErrorAction SilentlyContinue
}

}
