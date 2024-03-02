%global     debug_package %{nil}
%define     use_luajit 0

Name:       xmake
Version:    2.8.8
Release:    1%{?dist}
Summary:    A cross-platform build utility based on Lua

# Application and 3rd-party modules licensing:
# * xmake - Apache-2.0 -- Main tarball;
# * libsv - Public Domain -- static dependency;
# * tbox - Apache-2.0 -- static dependency;
# * xxHash - BSD -- static dependency;

License:    Apache-2.0 AND LicenseRef-Fedora-Public-Domain AND BSD
URL:        https://xmake.io
Source0:    https://github.com/xmake-io/xmake/releases/download/v%{version}/%{name}-v%{version}.tar.gz
Patch0:     0001-use-static-libsv-and-tbox.patch
Patch1:     0002-pkgconfig-unversioned-lua.patch

BuildRequires:  pkgconfig(ncurses)
BuildRequires:  pkgconfig(liblz4)
%if %{use_luajit}
BuildRequires:  pkgconfig(luajit)
%else
BuildRequires:  pkgconfig(lua) >= 5.4
%endif

BuildRequires:  gcc
BuildRequires:  gcc-c++

# Virtual provides for bundled libraries
Provides:  bundled(libsv) = 0.0.1
Provides:  bundled(libtbox) = 1.7.3

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
%autosetup -n %{name}-%{version} -p1

# Cleanup bundled deps
rm -rf core/src/{lua,luajit,lua-cjson,lz4,pdcurses}/*/

%build
%set_build_flags
%configure --external=yes
%if %{use_luajit}
  --runtime=luajit
%else
  --runtime=lua
%endif

%make_build

%install

mkdir -p %{buildroot}%{_mandir}/man1/
install -Dpm0755 build/xmake \
        %{buildroot}%{_bindir}/%{name}
install -Dpm0755 scripts/xrepo.sh \
        %{buildroot}%{_bindir}/xrepo
install -Dpm0644 scripts/man/*1 \
        %{buildroot}%{_mandir}/man1/
install -Dpm0644 xmake/scripts/completions/register-completions.bash \
        %{buildroot}%{_datadir}/bash-completion/completions/xmake
install -Dpm0644 xmake/scripts/completions/register-completions.fish \
        %{buildroot}%{_datadir}/fish/vendor_completions.d/xmake.fish
install -Dpm0644 xmake/scripts/completions/register-completions.zsh \
        %{buildroot}%{_datadir}/zsh/site-functions/xmake
cp -rp xmake \
        %{buildroot}%{_datadir}/xmake

%check
%{buildroot}%{_bindir}/%{name} --version
%{buildroot}%{_bindir}/xrepo --version

%files
%doc README.md CHANGELOG.md
%license LICENSE.md NOTICE.md
%{_bindir}/%{name}
%{_bindir}/xrepo
%{_datadir}/%{name}
%{_datadir}/bash-completion/completions/xmake
%{_datadir}/zsh/site-functions/xmake
%{_datadir}/fish/vendor_completions.d/xmake.fish
%{_mandir}/man1/*.1*

%changelog
* Tue Jul 11 2023 Zephyr Lykos <fedora@mochaa.ws> - 2.8.1-1
- Update to 2.8.1

* Sun Jun 04 2023 Zephyr Lykos <fedora@mochaa.ws> - 2.7.9-1
- Switch to release tarball
- Use system provided libs if possible
- Fix docs & manpage installation
- Install shell completions

* Sun Oct 18 2020 Ruki Wang <waruqi@gmail.com> - 2.3.8-1
- v2.3.8 released

* Mon Sep 14 2020 Ruki Wang <waruqi@gmail.com> - 2.3.7-1
- Initial Commit

