# libsv
libsv - Public domain semantic versioning in c

[![Build Status](https://travis-ci.org/uael/sv.svg?branch=master)](https://travis-ci.org/uael/sv)
[![Build status](https://ci.appveyor.com/api/projects/status/7li44f9agk0u4dxc?svg=true)](https://ci.appveyor.com/project/uael/sv)
[![codecov](https://codecov.io/gh/uael/sv/branch/master/graph/badge.svg)](https://codecov.io/gh/uael/sv)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/b21f7acd11a9437c8fe79b0600dc205e)](https://www.codacy.com/app/lucas.abel/sv?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=uael/sv&amp;utm_campaign=Badge_Grade)

# Topics
- [Introduction](#introduction)
- [License](#license)
- [Install](#install)
  - [xmake](#xmake)
  - [cmake](#cmake)
  - [autotools](#autotools)
- [Usage](#usage)
- [Credits](#credits)
- [Bugs, vulnerabilities and contributions](#bugs-vulnerabilities-and-contributions)
- [Resources](#resources)
- [Badges and static analysis](#badges-and-static-analysis)
  - [Travis CI](#travis-ci)
  - [Clang's Static Analyzer](#clangs-static-analyzer)

## Introduction

This is free and unencumbered software released into the public domain.
This  package  installs  a  C  language  library  implementing  semantic versioning for the C language.

## License

See the [UNLICENSE](https://github.com/uael/sv/blob/master/UNLICENSE) file.

## Install

### xmake

[Install xmake build system (A make-like build utility based on Lua)](http://xmake.io)

```bash
$ xmake
$ xmake check
$ xmake install
```

### cmake

```bash
$ mkdir build && cd build
$ cmake ..
$ make
$ make test
$ make install
```

### autotools

To install from a proper release tarball, do this:
```bash
$ cd libsv-3.1
$ mkdir build
$ cd build
$ ../configure
$ make
$ make check
$ make install
```
to inspect the available configuration options:
```bash
$ ../configure --help
```
The Makefile is designed to allow parallel builds, so we can do:
```bash
$ make -j4 all && make -j4 check
```
which,  on  a  4-core  CPU,   should  speed  up  building  and  checking significantly.
The  Makefile supports  the  DESTDIR environment  variable to  install files in a temporary location, example: to see what will happen:
```bash
$ make -n install DESTDIR=/tmp/libsv
```
to really do it:
```bash
$ make install DESTDIR=/tmp/libsv
```
After the installation it is  possible to verify the installed library against the test suite with:
```bash
$ make installcheck
```
From  a repository  checkout or  snapshot  (the ones  from the  Github site): we  must install the  GNU Autotools (GNU Automake,  GNU Autoconf, GNU Libtool),  then we must first  run the script "autogen.sh"  from the top source directory, to generate the needed files:
```bash
$ cd libsv
$ sh autogen.sh
```
notice  that  "autogen.sh"  will   run  the  programs  "autoreconf"  and "libtoolize"; the  latter is  selected through the  environment variable "LIBTOOLIZE",  whose  value  can  be  customised;  for  example  to  run "glibtoolize" rather than "libtoolize" we do:
```bash
$ LIBTOOLIZE=glibtoolize sh autogen.sh
```
After this the  procedure is the same  as the one for  building from a proper release tarball, but we have to enable maintainer mode:
```bash
$ ../configure --enable-maintainer-mode [options]
$ make
$ make check
$ make install
```

## Usage

```c
...
semver_t semver = {0};

semver(&semver, "v1.2.3-alpha.1");

assert(1 == semver.major);
assert(2 == semver.minor);
assert(3 == semver.patch);
assert(0 == memcmp("alpha", semver.prerelease.raw, sizeof("alpha")-1));
assert(0 == memcmp("1", semver.prerelease.next->raw, sizeof("1")-1));
assert(true == semver_rmatch(semver, "1.2.1 || >=1.2.3-alpha <1.2.5"));

semver_dtor(&semver);
...
```

### Versions

A "version" is described by the `v2.0.0` specification found at
<http://semver.org/>.

A leading `"v"` character is stripped off and ignored.

### Ranges

A `version range` is a set of `comparators` which specify versions
that satisfy the range.

A `comparator` is composed of an `operator` and a `version`.  The set
of primitive `operators` is:

* `<` Less than
* `<=` Less than or equal to
* `>` Greater than
* `>=` Greater than or equal to
* `=` Equal.  If no operator is specified, then equality is assumed,
  so this operator is optional, but MAY be included.

For example, the comparator `>=1.2.7` would match the versions
`1.2.7`, `1.2.8`, `2.5.3`, and `1.3.9`, but not the versions `1.2.6`
or `1.1.0`.

Comparators can be joined by whitespace to form a `comparator set`,
which is satisfied by the **intersection** of all of the comparators
it includes.

A range is composed of one or more comparator sets, joined by `||`.  A
version matches a range if and only if every comparator in at least
one of the `||`-separated comparator sets is satisfied by the version.

For example, the range `>=1.2.7 <1.3.0` would match the versions
`1.2.7`, `1.2.8`, and `1.2.99`, but not the versions `1.2.6`, `1.3.0`,
or `1.1.0`.

The range `1.2.7 || >=1.2.9 <2.0.0` would match the versions `1.2.7`,
`1.2.9`, and `1.4.6`, but not the versions `1.2.8` or `2.0.0`.

#### Prerelease Tags

If a version has a prerelease tag (for example, `1.2.3-alpha.3`) then
it will only be allowed to satisfy comparator sets if at least one
comparator with the same `[major, minor, patch]` tuple also has a
prerelease tag.

For example, the range `>1.2.3-alpha.3` would be allowed to match the
version `1.2.3-alpha.7`, but it would *not* be satisfied by
`3.4.5-alpha.9`, even though `3.4.5-alpha.9` is technically "greater
than" `1.2.3-alpha.3` according to the SemVer sort rules.  The version
range only accepts prerelease tags on the `1.2.3` version.  The
version `3.4.5` *would* satisfy the range, because it does not have a
prerelease flag, and `3.4.5` is greater than `1.2.3-alpha.7`.

The purpose for this behavior is twofold.  First, prerelease versions
frequently are updated very quickly, and contain many breaking changes
that are (by the author's design) not yet fit for public consumption.
Therefore, by default, they are excluded from range matching
semantics.

Second, a user who has opted into using a prerelease version has
clearly indicated the intent to use *that specific* set of
alpha/beta/rc versions.  By including a prerelease tag in the range,
the user is indicating that they are aware of the risk.  However, it
is still not appropriate to assume that they have opted into taking a
similar risk on the *next* set of prerelease versions.

#### Advanced Range Syntax

Advanced range syntax desugars to primitive comparators in
deterministic ways.

Advanced ranges may be combined in the same way as primitive
comparators using white space or `||`.

##### Hyphen Ranges `X.Y.Z - A.B.C`

Specifies an inclusive set.

* `1.2.3 - 2.3.4` := `>=1.2.3 <=2.3.4`

If a partial version is provided as the first version in the inclusive
range, then the missing pieces are replaced with zeroes.

* `1.2 - 2.3.4` := `>=1.2.0 <=2.3.4`

If a partial version is provided as the second version in the
inclusive range, then all versions that start with the supplied parts
of the tuple are accepted, but nothing that would be greater than the
provided tuple parts.

* `1.2.3 - 2.3` := `>=1.2.3 <2.4.0`
* `1.2.3 - 2` := `>=1.2.3 <3.0.0`

##### X-Ranges `1.2.x` `1.X` `1.2.*` `*`

Any of `X`, `x`, or `*` may be used to "stand in" for one of the
numeric values in the `[major, minor, patch]` tuple.

* `*` := `>=0.0.0` (Any version satisfies)
* `1.x` := `>=1.0.0 <2.0.0` (Matching major version)
* `1.2.x` := `>=1.2.0 <1.3.0` (Matching major and minor versions)

A partial version range is treated as an X-Range, so the special
character is in fact optional.

* `""` (empty string) := `*` := `>=0.0.0`
* `1` := `1.x.x` := `>=1.0.0 <2.0.0`
* `1.2` := `1.2.x` := `>=1.2.0 <1.3.0`

##### Tilde Ranges `~1.2.3` `~1.2` `~1`

Allows patch-level changes if a minor version is specified on the
comparator.  Allows minor-level changes if not.

* `~1.2.3` := `>=1.2.3 <1.(2+1).0` := `>=1.2.3 <1.3.0`
* `~1.2` := `>=1.2.0 <1.(2+1).0` := `>=1.2.0 <1.3.0` (Same as `1.2.x`)
* `~1` := `>=1.0.0 <(1+1).0.0` := `>=1.0.0 <2.0.0` (Same as `1.x`)
* `~0.2.3` := `>=0.2.3 <0.(2+1).0` := `>=0.2.3 <0.3.0`
* `~0.2` := `>=0.2.0 <0.(2+1).0` := `>=0.2.0 <0.3.0` (Same as `0.2.x`)
* `~0` := `>=0.0.0 <(0+1).0.0` := `>=0.0.0 <1.0.0` (Same as `0.x`)
* `~1.2.3-beta.2` := `>=1.2.3-beta.2 <1.3.0` Note that prereleases in
  the `1.2.3` version will be allowed, if they are greater than or
  equal to `beta.2`.  So, `1.2.3-beta.4` would be allowed, but
  `1.2.4-beta.2` would not, because it is a prerelease of a
  different `[major, minor, patch]` tuple.

#### Caret Ranges `^1.2.3` `^0.2.5` `^0.0.4`

Allows changes that do not modify the left-most non-zero digit in the
`[major, minor, patch]` tuple.  In other words, this allows patch and
minor updates for versions `1.0.0` and above, patch updates for
versions `0.X >=0.1.0`, and *no* updates for versions `0.0.X`.

Many authors treat a `0.x` version as if the `x` were the major
"breaking-change" indicator.

Caret ranges are ideal when an author may make breaking changes
between `0.2.4` and `0.3.0` releases, which is a common practice.
However, it presumes that there will *not* be breaking changes between
`0.2.4` and `0.2.5`.  It allows for changes that are presumed to be
additive (but non-breaking), according to commonly observed practices.

* `^1.2.3` := `>=1.2.3 <2.0.0`
* `^0.2.3` := `>=0.2.3 <0.3.0`
* `^0.0.3` := `>=0.0.3 <0.0.4`
* `^1.2.3-beta.2` := `>=1.2.3-beta.2 <2.0.0` Note that prereleases in
  the `1.2.3` version will be allowed, if they are greater than or
  equal to `beta.2`.  So, `1.2.3-beta.4` would be allowed, but
  `1.2.4-beta.2` would not, because it is a prerelease of a
  different `[major, minor, patch]` tuple.
* `^0.0.3-beta` := `>=0.0.3-beta <0.0.4`  Note that prereleases in the
  `0.0.3` version *only* will be allowed, if they are greater than or
  equal to `beta`.  So, `0.0.3-pr.2` would be allowed.

When parsing caret ranges, a missing `patch` value desugars to the
number `0`, but will allow flexibility within that value, even if the
major and minor versions are both `0`.

* `^1.2.x` := `>=1.2.0 <2.0.0`
* `^0.0.x` := `>=0.0.0 <0.1.0`
* `^0.0` := `>=0.0.0 <0.1.0`

A missing `minor` and `patch` values will desugar to zero, but also
allow flexibility within those values, even if the major version is
zero.

* `^1.x` := `>=1.0.0 <2.0.0`
* `^0.x` := `>=0.0.0 <1.0.0`

## Credits

The stuff was written by Lucas Abel <https://github.com/uael> and contributors
- Marco Maggi <https://github.com/marcomaggi>

## Bugs, vulnerabilities and contributions

Bug  and vulnerability  reports are  appreciated, all  the vulnerability reports  are  public; register  them  using  the  Issue Tracker  at  the project's Github  site.  For  contributions and  patches please  use the Pull Requests feature at the project's Github site.

Reports about the original code must be registered at:
<https://github.com/uael/sv/issues>

## Resources

Development of the original projects takes place at:
<https://github.com/uael/sv/>

the GNU Project software can be found here:
<https://www.gnu.org/>

## Badges and static analysis

### Travis CI

Travis CI is  a hosted, distributed continuous  integration service used to build and test software projects  hosted at GitHub.  We can find this project's dashboards at:
<https://travis-ci.org/uael/sv>

Usage of this service is configured through the file ".travis.yml".

### Clang's Static Analyzer

The Clang Static Analyzer is a source code analysis tool that finds bugs in C, C++, and Objective-C programs.  It is distributed along with Clang and we can find it at:
<http://clang-analyzer.llvm.org/>

Usage of this service is implemented with make rules; see the relevant section in the file "Makefile.am".
