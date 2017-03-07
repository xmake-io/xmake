# Maintainer: <waruqi@gmail.com>
# PKGBuild Create By: lumpyzhu <lumpy.zhu@gmail.com>

pkgname=xmake
pkgver=2.1
pkgrel=1
pkgdesc=""
arch=('x86_64')
url="https://github.com/tboox/xmake"
license=('Apache')
depends=('gcc')
makedepends=()
replace=('xmake')
provides=('xmake')
source=("$pkgname::https://codeload.github.com/tboox/xmake/zip/v${pkgver}.${pkgrel}")
md5sums=('fca9f41c64c1bb0838d399aad0ac3a2a')

prepare() {
    ls	  
}


build() {
    cd "$srcdir/${pkgname}-${pkgver}.${pkgrel}/core"
    make
}

package() {
    cd "$srcdir/${pkgname}-${pkgver}.${pkgrel}"
    install -Dvm755 "./core/bin/demo.pkg/bin/linux/$arch/demo.b" "${pkgdir}/opt/xmake/bin/xmake.bin"
    echo "#/!bin/sh
export XMAKE_PROGRAM_DIR=/opt/xmake/share
/opt/xmake/bin/xmake.bin "$@"
" >> ./xmake.sh
    install "./xmake.sh" "${pkgdir}/opt/xmake/bin/xmake"
    cp -vr "./xmake" "${pkgdir}/opt/xmake/share"
}
