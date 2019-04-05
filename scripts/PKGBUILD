# Maintainer: <waruqi@gmail.com>
# PKGBuild Create By: lumpyzhu <lumpy.zhu@gmail.com>

pkgname=xmake
pkgver=2.2.5
pkgrel=1
pkgdesc="A make-like build utility based on Lua"
arch=('i686' 'x86_64')
url="https://github.com/xmake-io/xmake"
license=('Apache')
makedepends=()
source=("$pkgname.zip::https://github.com/xmake-io/xmake/archive/v${pkgver}.zip")
sha256sums=('20e9bd6684be429d20cda69ff16e0fdacaaade80760a87c9e42b54e3661f214e')

build() {
    cd "$srcdir/${pkgname}-${pkgver}"
    make build
}

package() {
    cd "$srcdir/${pkgname}-${pkgver}"
    mkdir -p "${pkgdir}/usr/share"
    cp -r "./xmake" "${pkgdir}/usr/share/"
    install -Dm755 ./core/src/demo/demo.b "${pkgdir}/usr/share/xmake/xmake"
    echo "#!/bin/bash
export XMAKE_PROGRAM_DIR=/usr/share/xmake
/usr/share/xmake/xmake \"\$@\"
" > ./xmake.sh
    install -Dm755 "./xmake.sh" "${pkgdir}/usr/bin/xmake"
}
