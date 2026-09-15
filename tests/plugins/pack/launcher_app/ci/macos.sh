#!/bin/bash
# Runtime validation of the launcher feature for the dmg format (macos).
set -euo pipefail
cd "$(dirname "$0")/.."

xmake f -y -m release -P .
xmake pack -y --formats=dmg --autobuild=y -P .
DMG="$(find build -name '*.dmg' | head -1)"

rm -rf /tmp/dmgmount && mkdir -p /tmp/dmgmount
hdiutil attach "$DMG" -mountpoint /tmp/dmgmount -nobrowse

# the launcher wrapper lives at bin/<name>.app/Contents/MacOS/<name>
APPBIN="$(find /tmp/dmgmount -path '*/Contents/MacOS/launcher_app' | head -1)"
OUT="$("$APPBIN" mac-arg)"
echo "$OUT" | grep -q 'arg\[3\]=mac-arg'
echo "$OUT" | grep -q 'env=launcher-ok'

hdiutil detach /tmp/dmgmount -quiet
echo "== dmg ok =="
