# xmake getter
# usage: (in powershell)
#  Invoke-Expression (Invoke-Webrequest <my location> -UseBasicParsing).Content

$outfile=($env:TMP,$env:TEMP,'.' -ne $null)[0]+"\$pid-xmake-installer.exe"
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
xmake --version
