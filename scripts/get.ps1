# xmake getter
# usage: (in powershell)
#  Invoke-Expression (Invoke-Webrequest <my location> -UseBasicParsing).Content

$temppath=($env:TMP,$env:TEMP,'.' -ne $null)[0]
$outfile=$temppath+"\$pid-xmake-installer.exe"
try{
    Write-Output "$pid"|Out-File -FilePath "$outfile"
    Remove-Item "$outfile"
}catch{
    Write-Host 'Cannot write to temp path'
    Write-Host 'Please set environment var "TMP" to another path'
    Exit 1
}
$ver='v2.1.3'
Write-Host 'Start downloading... Hope amazon S3 is not broken again'
try{
    Invoke-Webrequest "https://github.com/tboox/xmake/releases/download/$ver/xmake-$ver.exe" -OutFile "$outfile"
}catch{
    Write-Host 'Download failed!'
    Write-Host 'Check your network or... the news of S3 break'
    Exit 1
}
Write-Host 'Start installation... Hope your antivirus doesn''t trouble'
$installdir=$HOME+'\xmake'
Write-Host "Install to $installdir"
try{
    Start-Process -FilePath "$outfile" -ArgumentList "/S /D=$installdir" -Wait
}catch{
    Remove-Item "$outfile"
    Write-Host 'Install failed!'
    Write-Host 'Close your antivirus then try again'
    Exit 1
}
Remove-Item "$outfile"
Write-Host 'Adding to PATH... almost done'
$env:Path+=";$installdir"
[Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path",[System.EnvironmentVariableTarget]::User)+";$installdir",[System.EnvironmentVariableTarget]::User)    # this step is optional because installer writes path to regedit
try{
    xmake --version
}catch{
    Write-Host 'Everything is showing installation has finished'
    Write-Host 'But xmake could not run... Why?'
    Exit 1
}
$branch='master'
Write-Host "Pulling xmake from branch $branch"
$outfile=$temppath+"\$pid-xmake-repo.zip"
try{
    Invoke-Webrequest "https://github.com/tboox/xmake/archive/$branch.zip" -OutFile "$outfile"
}catch{
    Write-Host 'Pull Failed!'
    Write-Host 'xmake is now available but may not be newest'
    Exit
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
    Write-Host 'Update Failed!'
    Write-Host 'xmake is now available but may not be newest'
}finally{
    Set-Location "$oldpwd" -ErrorAction SilentlyContinue
    Remove-Item "$outfile" -ErrorAction SilentlyContinue
    Remove-Item "$repodir" -Recurse -Force -ErrorAction SilentlyContinue
}
