#!/bin/bash
# Runtime validation of the launcher feature for linux pack formats.
# Runs in CI (root); also runnable locally as a normal user (uses unshare).
set -euo pipefail
cd "$(dirname "$0")/.."

# chroot into a fake root: as root directly, via passwordless sudo on CI
# runners, or via user namespaces on local dev boxes
run_chroot() {
    if [ "$(id -u)" = "0" ]; then
        chroot "$@"
    elif sudo -n true 2>/dev/null; then
        sudo chroot "$@"
    else
        unshare -Ur /usr/sbin/chroot "$@"
    fi
}

# populate a fake root so the wrapper's absolute /usr/bin/<name>-real resolves
setup_rootfs() {
    local root="$1"
    mkdir -p "$root/lib64" "$root/lib/x86_64-linux-gnu" "$root/bin"
    cp /lib64/ld-linux-x86-64.so.2 "$root/lib64/"
    cp /lib/x86_64-linux-gnu/libc.so.6 "$root/lib/x86_64-linux-gnu/"
    cp /bin/sh "$root/bin/"
}

echo "== appimage =="
xmake f -y -m release -p linux -a x86_64 -P .
xmake pack -y --formats=appimage --autobuild=y -P .
APP="$(find build -name '*.AppImage' | head -1)"
chmod +x "$APP"
OUT="$(APPIMAGE_EXTRACT_AND_RUN=1 "$APP" app-arg)"
echo "$OUT" | grep -q 'arg\[3\]=app-arg'
echo "$OUT" | grep -q 'env=launcher-ok'

echo "== rpm =="
xmake pack -y --formats=rpm --autobuild=y -P .
RPM="$(find build -name '*.rpm' ! -name '*.src.rpm' | head -1)"
rm -rf /tmp/rpmroot && mkdir -p /tmp/rpmroot
( cd /tmp/rpmroot && rpm2cpio "$OLDPWD/$RPM" | cpio -idm >/dev/null 2>&1 )
setup_rootfs /tmp/rpmroot
OUT="$(run_chroot /tmp/rpmroot /usr/bin/launcher_app rpm-arg)"
echo "$OUT" | grep -q 'arg\[3\]=rpm-arg'
echo "$OUT" | grep -q 'env=launcher-ok'

echo "== deb =="
xmake pack -y --formats=deb --autobuild=y -P .
DEB="$(find build -name '*.deb' | head -1)"
rm -rf /tmp/debroot && mkdir -p /tmp/debroot
dpkg-deb -x "$DEB" /tmp/debroot
setup_rootfs /tmp/debroot
OUT="$(run_chroot /tmp/debroot /usr/bin/launcher_app deb-arg)"
echo "$OUT" | grep -q 'arg\[3\]=deb-arg'
echo "$OUT" | grep -q 'env=launcher-ok'

echo "== runself =="
xmake pack -y --formats=runself --autobuild=y -P .
RUN="$(find build -name '*.run' | head -1)"
chmod +x "$RUN"
rm -rf /tmp/runself
OUT="$(script -qec "timeout 120 '$PWD/$RUN' --target /tmp/runself run-arg" /dev/null)"
echo "$OUT" | grep -q 'arg\[3\]=run-arg'
echo "$OUT" | grep -q 'env=launcher-ok'

echo "== nsis (build only, runtime needs windows) =="
xmake f -y -m release -p windows -a x64 --toolchain=zigcc -P .
xmake pack -y --formats=nsis --autobuild=y -P .
find build -name '*.exe' ! -path '*release*' | grep -q .

echo "== all linux formats ok =="
