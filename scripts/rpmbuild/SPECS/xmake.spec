%define     xmake_branch        master
%define     tbox_branch         dev
%define     sv_branch           xmake-core
%define     lua_cjson_branch    xmake-core
%define     luajit_branch       2.1-xmake
%define     _binaries_in_noarch_packages_terminate_build   0
%undefine   _disable_source_fetch

Name:       xmake
Version:    2.3.7
Release:    1%{?dist}
Summary:    A cross-platform build utility based on Lua
BuildArch:  noarch
License:    ASL 2.0
URL:        https://xmake.io
Source0:    https://github.com/xmake-io/xmake/archive/%{xmake_branch}.tar.gz#/xmake-%{xmake_branch}.tar.gz
Source1:    https://github.com/tboox/tbox/archive/%{tbox_branch}.tar.gz#/tbox-%{tbox_branch}.tar.gz
Source2:    https://github.com/xmake-io/xmake-core-luajit/archive/v%{luajit_branch}.tar.gz#/xmake-core-luajit-%{luajit_branch}.tar.gz
Source3:    https://github.com/xmake-io/xmake-core-sv/archive/%{sv_branch}.tar.gz#/xmake-core-sv-%{sv_branch}.tar.gz
Source4:    https://github.com/xmake-io/xmake-core-lua-cjson/archive/%{lua_cjson_branch}.tar.gz#/xmake-core-lua-cjson-%{lua_cjson_branch}.tar.gz

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
%setup -q -T -b 1 -n tbox-%{tbox_branch}
cd ..
%setup -q -T -b 2 -n xmake-core-luajit-%{luajit_branch}
cd ..
%setup -q -T -b 3 -n xmake-core-sv-%{sv_branch}
cd ..
%setup -q -T -b 4 -n xmake-core-lua-cjson-%{lua_cjson_branch}
cd ..
%setup -q -T -b 0 -n xmake-%{xmake_branch}
rm -rf core/src/sv/sv
rm -rf core/src/tbox/tbox
rm -rf core/src/luajit/luajit
rm -rf core/src/lua-cjson/lua-cjson
ln -s `pwd`/../tbox-dev core/src/tbox/tbox
ln -s `pwd`/../xmake-core-sv-%{sv_branch} core/src/sv/sv
ln -s `pwd`/../xmake-core-luajit-%{luajit_branch} core/src/luajit/luajit
ln -s `pwd`/../xmake-core-lua-cjson-%{lua_cjson_branch} core/src/lua-cjson/lua-cjson

%build
%set_build_flags
%make_build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}
cp -p -r xmake %{buildroot}%{_datadir}/%{name}
cp -p core/src/demo/demo.b %{buildroot}%{_bindir}/%{name}
chmod 755 %{buildroot}%{_bindir}/%{name}
cp -p README.md %{buildroot}%{_datadir}
cp -p LICENSE.md %{buildroot}%{_datadir}

%check
XMAKE_ROOT=y %{buildroot}%{_bindir}/%{name} --version

%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%doc %{_datadir}/README.md
%license %{_datadir}/LICENSE.md

%changelog
* Mon Sep 14 2020 Ruki Wang <waruqi@gmail.com> - 2.3.7-1
- Initial Commit

