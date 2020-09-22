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

%define _binaries_in_noarch_packages_terminate_build   0
 
%prep
rm -rf xmake-v%{version}
git clone --recurse-submodules https://github.com/xmake-io/xmake.git -b dev xmake-v%{version}
cd xmake-v%{version}

%build
make build
 
%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir} 
cp -r xmake %{buildroot}%{_datadir}/%{name}
cp core/src/demo/demo.b %{buildroot}%{_bindir}/%{name} 
chmod 755 %{buildroot}%{_bindir}/%{name}

%check
%{buildroot}%{_bindir}/%{name} --version

%clean
rm -rf %{buildroot}

%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%doc README.md
%license LICENSE.md
 
%changelog
* Mon Sep 14 2020 Ruki Wang <waruqi@gmail.com> - 2.3.7-1
- Initial Commit

