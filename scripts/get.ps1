# xmake getter
# usage: (in powershell)
#  Invoke-Expression (Invoke-Webrequest <my location> -UseBasicParsing).Content

$outfile=($env:TEMP,$env:TMP,'.' -ne $null)[0]+"\$pid-xmake-installer.exe"
$ver='v2.1.3'
Invoke-Webrequest "https://github.com/tboox/xmake/releases/download/$ver/xmake-$ver.exe" -OutFile "$outfile" -ErrorAction Stop
Start-Process -FilePath "$outfile" -ArgumentList '/S /D=C:\xmake' -Wait -ErrorAction Stop
Remove-Item "$outfile"
$env:Path+=";C:\xmake"
[Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path",[System.EnvironmentVariableTarget]::User)+";C:\xmake",[System.EnvironmentVariableTarget]::User)
xmake --version
