dnl @configure_input@
dnl

AC_PREREQ([2.69])
AC_INIT([libsv],[0.0.1],,[libsv],[http://github.com/uael/sv])
AC_COPYRIGHT([This is free and unencumbered software released into the public domain.

Anyone  is  free  to  copy,  modify, publish,  use,  compile,  sell,  or
distribute this  software, either in source  code form or as  a compiled
binary, for any purpose, commercial or non-commercial, and by any means.

In jurisdictions that recognize copyright laws, the author or authors of
this software dedicate any and all copyright interest in the software to
the public domain. We make this dedication for the benefit of the public
at large  and to the  detriment of our  heirs and successors.  We intend
this dedication  to be an overt  act of relinquishment in  perpetuity of
all present and future rights to this software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS",  WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR   IMPLIED,  INCLUDING   BUT  NOT   LIMITED  TO   THE  WARRANTIES   OF
MERCHANTABILITY, FITNESS  FOR A PARTICULAR PURPOSE  AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION  OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT  OF OR  IN CONNECTION WITH  THE SOFTWARE OR  THE USE  OR OTHER
DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>
])
AC_CONFIG_SRCDIR([src])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([scripts])
AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET
AM_INIT_AUTOMAKE([foreign dist-xz no-dist-gzip subdir-objects])
AM_MAINTAINER_MODE

AM_PROG_AR
AC_PROG_INSTALL
AC_PROG_LN_S
AC_PROG_MAKE_SET
AC_PROG_MKDIR_P

LT_PREREQ([2.4])
LT_INIT

dnl This is the version stored in the pkg-config data file.
AC_SUBST([LIBSV_PKG_CONFIG_VERSION],[0.0.1])

dnl page
#### libraries interface version

MM_LIBTOOL_LIBRARY_VERSIONS([libsv],1,0,0)

dnl page
#### basic system inspection

AC_LANG([C])
AM_PROG_AS
AC_PROG_CC_C99
AM_PROG_CC_C_O
AC_HEADER_STDC

AC_CACHE_SAVE

dnl page
#### finish

AC_CONFIG_FILES([Makefile]
   [scripts/libsv.pc])
AC_OUTPUT

### end of file
# Local Variables:
# mode: autoconf
# page-delimiter: "^dnl page"
# End:
