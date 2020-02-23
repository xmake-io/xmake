# Maintainer: <waruqi@gmail.com>
# PKGBuild Create By: lumpyzhu <lumpy.zhu@gmail.com>

pkgname=xmake
pkgver=2.3.1
pkgrel=1
pkgdesc="A make-like build utility based on Lua"
arch=('i686' 'x86_64')
url="https://github.com/xmake-io/xmake"
license=('Apache')
makedepends=()
source=("$pkgname.tar.gz::https://cdn.jsdelivr.net/gh/xmake-mirror/xmake-releases@${pkgver}/xmake-v${pkgver}.tar.gz")
sha256sums=('69309bb06cd8eb6f4bf30c68bdbccb9bc7df4c8240c72778e98ebe752d864382')

build() {
    cd "$srcdir"
    make build
}

package() {
    cd "$srcdir"
    make install prefix="${pkgdir}/usr"
}
