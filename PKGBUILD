# Maintainer: <waruqi@gmail.com>
# PKGBuild Create By: lumpyzhu <lumpy.zhu@gmail.com>

pkgname=xmake
pkgver=2.1.1
pkgrel=1
pkgdesc="A make-like build utility based on Lua"
arch=('i686' 'x86_64')
url="https://github.com/tboox/xmake"
license=('Apache')
makedepends=()
source=("$pkgname.zip::https://github.com/tboox/xmake/archive/v${pkgver}.zip")
md5sums=('fca9f41c64c1bb0838d399aad0ac3a2a')

build() {
    cd "$srcdir/${pkgname}-${pkgver}"
    cd ./core
    make f DEBUG=n
    make r
}

package() {
    cd "$srcdir/${pkgname}-${pkgver}"
    mkdir -p "${pkgdir}/usr/local/share"
    mkdir -p "${pkgdir}/usr/local/bin"
    cp -vr "./xmake" "${pkgdir}/usr/local/share/"
    install -Dvm755 `find ./core/bin/demo.pkg/bin/linux/ -name "demo.b"` "${pkgdir}/usr/local/share/xmake/xmake"
    echo "#/!bin/bash
export XMAKE_PROGRAM_DIR=/usr/local/share/xmake
/usr/local/share/xmake/xmake \"\$@\"
" > ./xmake.sh
    install "./xmake.sh" "${pkgdir}/usr/local/bin/xmake"
}
