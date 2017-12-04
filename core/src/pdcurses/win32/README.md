PDCurses for Win32
==================

This directory contains PDCurses source code files specific to Win32 
console mode (Win9x/Me/NT/2k/XP/Vista).


Building
--------

- Choose the appropriate makefile for your compiler:

        bccwin32.mak  - Borland C++ 4.0.2+
        dmcwin32.mak  - Digital Mars
        gccwin32.mak  - Cygnus GNU Compiler
        lccwin32.mak  - LCC-Win32
        mingwin32.mak - MinGW
        vcwin32.mak   - Microsoft Visual C++ 2.0+
        wccwin32.mak  - Open Watcom 1.8+

- Optionally, you can build in a different directory than the platform
  directory by setting PDCURSES_SRCDIR to point to the directory where
  you unpacked PDCurses, and changing to your target directory:

        set PDCURSES_SRCDIR=c:\pdcurses

  This won't work with the LCC or Digital Mars makefiles, nor will the
  options described below.

- Build it:

        make -f makefilename

  (For Watcom, use "wmake" instead of "make"; for MSVC, "nmake".) You'll
  get the libraries (pdcurses.lib or .a, depending on your compiler; and
  panel.lib or .a), the demos (*.exe), and a lot of object files. Note
  that the panel library is just a copy of the main library, provided
  for convenience; both panel and curses functions are in the main
  library.

  You can also give the optional parameter "WIDE=Y", to build the 
  library with wide-character (Unicode) support:

        make -f mingwin32.mak WIDE=Y

  When built this way, the library is not compatible with Windows 9x,
  unless you also link with the Microsoft Layer for Unicode (not
  tested).

  Another option, "UTF8=Y", makes PDCurses ignore the system locale, and 
  treat all narrow-character strings as UTF-8. This option has no effect 
  unless WIDE=Y is also set. Use it to get around the poor support for 
  UTF-8 in the Win32 console:

        make -f mingwin32.mak WIDE=Y UTF8=Y

  You can also use the optional parameter "DLL=Y" with Visual C++,
  MinGW or Cygwin, to build the library as a DLL:

        nmake -f vcwin32.mak WIDE=Y DLL=Y

  When you build the library as a Windows DLL, you must always define
  PDC_DLL_BUILD when linking against it. (Or, if you only want to use
  the DLL, you could add this definition to your curses.h.)


Distribution Status
-------------------

The files in this directory are released to the Public Domain.


Acknowledgements
----------------

Generic Win32 port was provided by Chris Szurgot <szurgot@itribe.net>
