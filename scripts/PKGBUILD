# Maintainer: <waruqi@gmail.com>
# PKGBuild Create By: lumpyzhu <lumpy.zhu@gmail.com>

pkgname=xmake
pkgver=2.2.9
pkgrel=2
pkgdesc="A make-like build utility based on Lua"
arch=('i686' 'x86_64')
url="https://github.com/xmake-io/xmake"
license=('Apache')
makedepends=()
source=("$pkgname.tar.gz::https://cdn.jsdelivr.net/gh/xmake-mirror/xmake-releases@${pkgver}/xmake-v${pkgver}.tar.gz")
sha256sums=('7d7b4b368808c78cda4bcdd00a140cd8b4cab8f32c7b3c31aa22fdd08dde4940')

build() {
    cd "$srcdir"
    make build
}

package() {
    cd "$srcdir"
    make install prefix="${pkgdir}/usr"
}
