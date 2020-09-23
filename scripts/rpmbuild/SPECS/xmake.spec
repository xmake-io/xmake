Name:       xmake
Version:    2.3.7
Release:    1%{?dist}
Summary:    A cross-platform build utility based on Lua 
BuildArch:  noarch
License:    Apache-2.0
URL:        https://xmake.io

BuildRequires:  gcc-c++
BuildRequires:  ncurses-devel
BuildRequires:  readline-devel
 
%description
It is a lightweight cross-platform build utility based on Lua. 
It uses xmake.lua to maintain project builds. Compared with makefile/CMakeLists.txt, 
the configuration syntax is more concise and intuitive. 
It is very friendly to novices and can quickly get started in a short time. 
Let users focus more on actual project development.

It can compile the project directly like Make/Ninja, or 
generate project files like CMake/Meson, and it also has a built-in package management 
system to help users solve the integrated use of C/C++ dependent libraries.

%define xmake_commitid dev
%define tbox_commitid dev
%define luajit_commitid 2.1-xmake
%define sv_commitid xmake-core
%define lua_cjson_commitid xmake-core
%define xmake_basename xmake-v%{version}
%define _binaries_in_noarch_packages_terminate_build   0
 
%prep
# pull xmake sources, we cannot use git because it will crash on fedora-armhfp
rm -rf %{xmake_basename}
wget https://github.com/xmake-io/xmake/archive/%{xmake_commitid}.zip -O xmake-%{xmake_commitid}.zip
unzip xmake-%{xmake_commitid}.zip
mv xmake-%{xmake_commitid} %{xmake_basename}  

# pull tbox sources
wget https://github.com/tboox/tbox/archive/%{tbox_commitid}.zip -O tbox-%{tbox_commitid}.zip
unzip tbox-%{tbox_commitid}.zip
rm -rf %{xmake_basename}/core/src/tbox/tbox
mv tbox-%{tbox_commitid} %{xmake_basename}/core/src/tbox/tbox  

# pull luajit sources
wget https://github.com/xmake-io/xmake-core-luajit/archive/v%{luajit_commitid}.zip -O luajit-%{luajit_commitid}.zip
unzip luajit-%{luajit_commitid}.zip
rm -rf %{xmake_basename}/core/src/luajit/luajit  
mv xmake-core-luajit-%{luajit_commitid} %{xmake_basename}/core/src/luajit/luajit  

# pull sv sources
wget https://github.com/xmake-io/xmake-core-sv/archive/%{sv_commitid}.zip -O sv-%{sv_commitid}.zip
unzip sv-%{sv_commitid}.zip
rm -rf %{xmake_basename}/core/src/sv/sv  
mv xmake-core-sv-%{sv_commitid} %{xmake_basename}/core/src/sv/sv  

# pull lua-cjson sources
wget https://github.com/xmake-io/xmake-core-lua-cjson/archive/%{lua_cjson_commitid}.zip -O lua-cjson-%{lua_cjson_commitid}.zip
unzip lua-cjson-%{lua_cjson_commitid}.zip
rm -rf %{xmake_basename}/core/src/lua-cjson/lua-cjson  
mv xmake-core-lua-cjson-%{lua_cjson_commitid} %{xmake_basename}/core/src/lua-cjson/lua-cjson   

%build
cd %{xmake_basename} 
make build
 
%install
cd %{xmake_basename} 
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir} 
cp -r xmake %{buildroot}%{_datadir}/%{name}
cp core/src/demo/demo.b %{buildroot}%{_bindir}/%{name} 
chmod 755 %{buildroot}%{_bindir}/%{name}
cp README.md %{buildroot}%{_datadir}
cp LICENSE.md %{buildroot}%{_datadir}

%check
%{buildroot}%{_bindir}/%{name} --version

%clean
rm -rf %{buildroot}

%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%doc %{_datadir}/README.md
%license %{_datadir}/LICENSE.md
 
%changelog
* Mon Sep 14 2020 Ruki Wang <waruqi@gmail.com> - 2.3.7-1
- Initial Commit

