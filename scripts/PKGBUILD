# Maintainer: <waruqi@gmail.com>
# PKGBuild Create By: lumpyzhu <lumpy.zhu@gmail.com>

pkgname=xmake
pkgver=2.2.3
pkgrel=1
pkgdesc="A make-like build utility based on Lua"
arch=('i686' 'x86_64')
url="https://github.com/tboox/xmake"
license=('Apache')
makedepends=()
source=("$pkgname.zip::https://github.com/tboox/xmake/archive/v${pkgver}.zip")
sha256sums=('e89b6e45b93d8965aeb93d069c17f60723ecd1389b06bd9c6147ce1181e7cad2')

build() {
    cd "$srcdir/${pkgname}-${pkgver}"
    make build
}

package() {
    cd "$srcdir/${pkgname}-${pkgver}"
    mkdir -p "${pkgdir}/usr/share"
    cp -r "./xmake" "${pkgdir}/usr/share/"
    install -Dm755 ./core/src/demo/demo.b "${pkgdir}/usr/share/xmake/xmake"
    echo "#/!bin/bash
export XMAKE_PROGRAM_DIR=/usr/share/xmake
/usr/share/xmake/xmake \"\$@\"
" > ./xmake.sh
    install -Dm755 "./xmake.sh" "${pkgdir}/usr/bin/xmake"
}
