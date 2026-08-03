# Runtime validation of the launcher feature for windows formats (nsis/wix).
# Runs on a windows CI runner (real cmd, so the .cmd wrapper works).
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

Write-Output '== nsis =='
xmake f -y -m release -P .
xmake pack -y --formats=nsis --autobuild=y -P .
$exe = Get-ChildItem -Path 'build' -Recurse -Filter '*.exe' |
    Where-Object { $_.FullName -notmatch '\\release\\' -and $_.FullName -match 'xpack' } |
    Select-Object -First 1
if (-not $exe) { throw 'nsis installer not produced' }

# silent install to a space-free path, then run the .cmd wrapper
& $exe.FullName /S /NOADMIN /D=C:\launcher
if ($LASTEXITCODE -ne 0) { throw "installer failed: $LASTEXITCODE" }

# the /D override may not be honored by the UAC-laced installer, so locate the
# installed wrapper wherever it ended up instead of assuming one path
$cmd = $null
foreach ($root in @('C:\launcher', 'C:\Program Files\launcherapp', 'C:\Program Files (x86)\launcherapp')) {
    $p = Join-Path $root 'bin\launcher_app.cmd'
    if (Test-Path $p) { $cmd = $p; break }
}
if (-not $cmd) {
    $cmd = Get-ChildItem -Path 'C:\' -Recurse -Filter 'launcher_app.cmd' -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $cmd) { throw 'launcher_app.cmd not installed anywhere' }
Write-Output "installed wrapper: $cmd"

$out = & $cmd --mode test win-arg 2>&1
$outText = $out -join "`n"
if ($outText -notmatch 'arg\[3\]=win-arg') { throw "args not forwarded: $outText" }
if ($outText -notmatch 'env=launcher-ok') { throw "env not set: $outText" }

Write-Output '== wix (best-effort, needs the wix tool) =='
if (Get-Command wix -ErrorAction SilentlyContinue) {
    xmake pack -y --formats=wix --autobuild=y -P .
    $msi = Get-ChildItem -Path 'build' -Recurse -Filter '*.msi' | Select-Object -First 1
    if (-not $msi) { throw 'msi not produced' }
} else {
    Write-Output 'wix tool not installed; skipping wix build'
}

Write-Output '== windows formats ok =='
