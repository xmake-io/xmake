# Maintainer: <waruqi@gmail.com>
# PKGBuild Create By: lumpyzhu <lumpy.zhu@gmail.com>

pkgname=xmake
pkgver=2.1.1
pkgrel=1
pkgdesc="A make-like build utility based on Lua"
arch=('i686' 'x86_64')
url="https://github.com/tboox/xmake"
license=('Apache')
depends=('gcc')
makedepends=()
provides=('xmake')
source=("$pkgname.zip::https://coding.net/u/waruqi/p/xmake/git/archive/v${pkgver}.zip")
md5sums=('d993449030de492bf17ac6f6f967da91')

prepare() {
    ls	  
}


build() {
    cd `find $srcdir -name "${pkgname}-*${pkgver}"`
    cd ./core
    make f DEBUG=n
    make r
}

package() {
    cd `find $srcdir -name "${pkgname}-*${pkgver}"`
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
