%define     xmake_revision       d1e9267d758ed360976bd4ef2eee3793f6ed7716
%define     tbox_revision        ac38b67ffe39d2bca5860a4bc91ec1f87cd71861
%define     sv_revision          035262773da0500367cb88e6f30197908159a348
%define     lua_cjson_revision   ddcecf3b24b71421e7b4a2962f1fbcc0297e0c1e
%define     luajit_revision      e9af1abec542e6f9851ff2368e7f196b6382a44c
%define     lua_revision         eadd8c7178c79c814ecca9652973a9b9dd4cc71b
%define     lz4_revision         033606ef259ef2852f6ae1e8ec7a10c641417654
%define     _binaries_in_noarch_packages_terminate_build   0
%undefine   _disable_source_fetch

Name:       xmake
Version:    2.7.1
Release:    1%{?dist}
Summary:    A cross-platform build utility based on Lua
BuildArch:  noarch
License:    ASL 2.0
URL:        https://xmake.io
Source0:    https://github.com/xmake-io/xmake/archive/%{xmake_revision}.tar.gz#/xmake-%{xmake_revision}.tar.gz
Source1:    https://github.com/tboox/tbox/archive/%{tbox_revision}.tar.gz#/tbox-%{tbox_revision}.tar.gz
Source2:    https://github.com/xmake-io/xmake-core-lua/archive/%{lua_revision}.tar.gz#/xmake-core-lua-%{lua_revision}.tar.gz
Source3:    https://github.com/xmake-io/xmake-core-luajit/archive/%{luajit_revision}.tar.gz#/xmake-core-luajit-%{luajit_revision}.tar.gz
Source4:    https://github.com/xmake-io/xmake-core-sv/archive/%{sv_revision}.tar.gz#/xmake-core-sv-%{sv_revision}.tar.gz
Source5:    https://github.com/xmake-io/xmake-core-lua-cjson/archive/%{lua_cjson_revision}.tar.gz#/xmake-core-lua-cjson-%{lua_cjson_revision}.tar.gz
Source6:    https://github.com/xmake-io/xmake-core-lz4/archive/%{lz4_revision}.tar.gz#/xmake-core-lz4-%{lz4_revision}.tar.gz

BuildRequires:  gcc-c++
BuildRequires:  ncurses-devel
BuildRequires:  readline-devel

%description
xmake is a lightweight cross-platform build utility based on Lua.

It uses xmake.lua to maintain project builds. Compared with makefile/CMakeLists.txt,
the configuration syntax is more concise and intuitive.
It is very friendly to novices and can quickly get started in a short time.
Let users focus more on actual project development.

It can compile the project directly like Make/Ninja, or
generate project files like CMake/Meson, and it also has a built-in package management
system to help users solve the integrated use of C/C++ dependent libraries.

%prep
%setup -q -T -b 1 -n tbox-%{tbox_revision}
cd ..
%setup -q -T -b 2 -n xmake-core-lua-%{lua_revision}
cd ..
%setup -q -T -b 3 -n xmake-core-luajit-%{luajit_revision}
cd ..
%setup -q -T -b 4 -n xmake-core-sv-%{sv_revision}
cd ..
%setup -q -T -b 5 -n xmake-core-lua-cjson-%{lua_cjson_revision}
cd ..
%setup -q -T -b 6 -n xmake-core-lz4-%{lz4_revision}
cd ..
%setup -q -T -b 0 -n xmake-%{xmake_revision}
rm -rf core/src/sv/sv
rm -rf core/src/tbox/tbox
rm -rf core/src/lua/lua
rm -rf core/src/luajit/luajit
rm -rf core/src/lua-cjson/lua-cjson
rm -rf core/src/lz4/lz4
ln -s `pwd`/../tbox-%{tbox_revision} core/src/tbox/tbox
ln -s `pwd`/../xmake-core-sv-%{sv_revision} core/src/sv/sv
ln -s `pwd`/../xmake-core-lua-%{lua_revision} core/src/lua/lua
ln -s `pwd`/../xmake-core-luajit-%{luajit_revision} core/src/luajit/luajit
ln -s `pwd`/../xmake-core-lua-cjson-%{lua_cjson_revision} core/src/lua-cjson/lua-cjson
ln -s `pwd`/../xmake-core-lz4-%{lz4_revision} core/src/lz4/lz4

%build
%if 0%{?suse_version} && 0%{?suse_version} < 1550
export CFLAGS="%{optflags}"
export CXXFLAGS="%{optflags}"
%else
%set_build_flags
%endif
%make_build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}
cp -p -r xmake %{buildroot}%{_datadir}/%{name}
cp -p core/src/demo/demo.b %{buildroot}%{_bindir}/%{name}
chmod 755 %{buildroot}%{_bindir}/%{name}
cp -p README.md %{buildroot}%{_datadir}
cp -p LICENSE.md %{buildroot}%{_datadir}
cp -p scripts/xrepo.sh %{buildroot}%{_bindir}/xrepo
chmod 755 %{buildroot}%{_bindir}/xrepo

%check
%{buildroot}%{_bindir}/%{name} --version
%{buildroot}%{_bindir}/xrepo --version

%files
%{_bindir}/%{name}
%{_bindir}/xrepo
%{_datadir}/%{name}
%doc %{_datadir}/README.md
%license %{_datadir}/LICENSE.md

%changelog
* Sun Oct 18 2020 Ruki Wang <waruqi@gmail.com> - 2.3.8-1
- v2.3.8 released

* Mon Sep 14 2020 Ruki Wang <waruqi@gmail.com> - 2.3.7-1
- Initial Commit

