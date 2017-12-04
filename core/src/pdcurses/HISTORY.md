PDCurses 3.4 - 2008/09/08
=========================

Nothing much new this time, but I've been sitting on some bug fixes for 
almost a year, so it's overdue. Apart from bugs, the main changes are in 
the documentation.

New features:

- setsyx() is now a function rather than a macro.

Bug fixes and such:

- In x11, the xc_atrtab table size was under-calculated by half, 
  resulting in crashes at (oddly) certain line counts. (It should've 
  crashed a lot more.) Reported by Mark Hessling.

- Test for moved cursor was omitting the window origin offset. Reported 
  by Carey Evans.

- Is DOS and OS/2, the value for max items in key_table was still wrong.
  Reported by C.E.

- Changed isendwin() so it won't crash after delscreen().

- Ensure zero-termination in PDC_mbstowcs() and PDC_wcstombs(). 

- Disable QuickEdit Mode when enabling mouse input for the Win32 
  console; reported by "Zalapkrakna".

- Fix for building under Innotek C (I hope). Report by Elbert Pol, fix
  courtesy of Paul Smedley.

- Unified exports list with no duplicates -- pdcurses.def is now built
  from components at compile time.

- Don't install curspriv.h, and don't include it with binary
  distributions.

- Building DLLs with LCC is no longer supported, due to the primitive
  nature of its make.exe.

- Export the terminfo stub functions from the DLLs, too.

- Added support for Apple's ".dylib" in configure. Suggested by Marc 
  Vaillant (who says it's needed with OS 10.5.)

- In sdl1/Makefile.mng, ensure that CC is set.

- In the gcc makefiles, "$?" didn't really have the desired effect --
  _all_ the dependencies showed up on the command line, including
  curses.h, and pdcurses.a twice.  And apparently, this can mess up some
  old version (?) of MinGW. So, revert to spelling out "tuidemo.o
  tui.o". Reported by "Howard L."

- Extensive documentation revision and reorganizing. More to do here. 
  For example, I moved the build instructions from INSTALL (which never 
  really described installation) to the platform-specific READMEs. 

- New indentation standard: four spaces, no tabs.

------------------------------------------------------------------------

PDCurses 3.3 - 2007/07/11
=========================

This release adds an SDL backend, refines the demos, and is faster in 
some cases.

New features:

- SDL port. See INSTALL, doc/sdl.txt and sdl1/* for details.

- Double-buffering -- minimize screen writes by checking, in doupdate()
  and wnoutrefresh(), whether the changes to curscr are really changes.
  In most cases, this makes no difference (writes were already limited
  to areas marked as changed), but it can greatly reduce the overhead
  from touchwin(). It also helps if you have small, separated updates on
  the same line.

- The PDC_RGB colors can now be used, or not, with any platform (as long
  as the same options are used when compiling both the library and
  apps). This may help if you have apps that are hardwired to assume
  certain definitions.

- Restored the use_default_colors() stuff from the ncurses versions of
  the rain and worm demos, to make them "transparent" (this is useful
  now, with the SDL port); added transparency to newdemo.

- Added setlocale() to tuidemo, to make it easier to browse files with
  non-ASCII characters.

- Sped up firework demo by replacing unneeded clear() and init_pair()
  calls.

- Allow exit from ptest demo by typing 'q'.

- New functions for implementors: PDC_pair_content() and PDC_init_pair()
  (the old pdc_atrtab stuff was arguably the last remnant of code in the
  pdcurses directory that was based on platform details).

Bug fixes and such:

- Implicit wrefresh() needs to be called from wgetch() when the window's 
  cursor position is changed, even if there are no other changes.

- Set SP->audible on a per-platform basis, as was documented in
  IMPLEMNT, but not actually being done.

- Minor tweaks for efficiency and readability, notably with wscrl().

- tuidemo didn't work correctly on monochrome screens when A_COLOR was
  defined -- the color pair numbers appeared as the corresponding
  character; also, the input box was (I now realize) broken with ncurses
  since our 2.7, and broke more subtly with PDCurses' new implicit
  refresh handling; also, the path to the default file for the Browse
  function was a bit off.

- Assume in the demos that curs_set() is always available -- there's no
  good test for this, and the existing tests were bogus.

- Made the command-line parameter for ptest work. (If given an argument,
  it delays that number of milliseconds between changes, instead of
  waiting for a key, and automatically loops five times.)

- Building the Win32 DLL with MinGW or Cygwin wouldn't work from outside
  the platform directory.

- Building the X11 port with Cygwin required manually editing the 
  Makefile after configuring; no longer. Reported by Warren W. Gay.

- Minor tightening of configure and makefiles.

- Bogus references to "ACS_BLCORNER" in the border man page. Reported by
  "Walrii".

- slk_wlabel() was not documented.

- Spelling cleanup.

- Changed RCSIDs to not end with a semicolon -- avoids warnings when
  compiling with the -pedantic option.

- Merged latin-1.txt into x11.txt.

- Updated config.guess and config.sub to more recent versions.

------------------------------------------------------------------------

PDCurses 3.2 - 2007/06/06
=========================

This release mainly covers changes to the build process, along with a 
few structural changes.

New features:

- The panel library has been folded into the main library. What this
  means is that you no longer need to specify "-lpanel" or equivalent
  when linking programs that use panel functionality with PDCurses;
  however, panel.lib/.a is still provided (as a copy of pdcurses.lib/.a)
  so that you can, optionally, build your projects with no changes. It
  also means that panel functionality is available with the DLL or
  shared library. Note that panel.h remains separate from curses.h.

- Setting the PDCURSES_SRCDIR environment variable is no longer required
  before building, unless you want to build in a location other than the
  platform directory. (See INSTALL.)

- MinGW and Cygwin makefiles support building DLLs, via the "DLL=Y"
  option. Partly due to Timofei Shatrov.

- Support for the Digital Mars compiler.

- Watcom makefiles now use the "loaddll" feature.

Bug fixes and such:

- Eliminated the platform defines (DOS, WIN32, OS2, XCURSES) from
  curses.h, except for X11-specific SCREEN elements and functions.
  Dynamically-linked X11 apps built against an old version will have
  their red and blue swapped until rebuilt. (You can define PDC_RGB to
  build the library with the old color scheme, but it would also have to
  be defined when building any new app.) Any app that depends on
  PDCurses to determine the platform it's building on will have to make
  other arrangements.

- Documentation cleanup -- added more details; removed some content that
  didn't apply to PDCurses; moved the doc-building tool to the doc
  directory; changed *.man to *.txt.

- The EMX makefile now accepts "DLL=Y", builds pdcurses.dll instead of
  curses.dll, builds either the static library or the DLL (not both at
  once), and links all the demos with the DLL when building it.

- In Win32, read the registry only when needed: when init_color() or 
  color_content() is called, instead of at startup.

- A few additional consts in declarations.

- The Win32 compilers that build DLLs now use common .def files.

- panel.h functions sorted by name, as with other .h files; curses.h is
  no longer included by repeated inclusions of panel.h or term.h.

- Simplified Borland makefiles.

- Makefile.aix.in depended on a file, xcurses.exp, that was never there.
  This problem was fixed as part of the change to common .def files; 
  however, I still haven't been able to test building on AIX.

------------------------------------------------------------------------

PDCurses 3.1 - 2007/05/03
=========================

Primarily clipboard-related fixes, and special UTF-8 support.

New features:

- "Force UTF-8" mode, a compile-time option to force the use of UTF-8
  for multibyte strings, instead of the system locale. (Mainly for
  Windows, where UTF-8 doesn't work well in the console.) See INSTALL.

- Multibyte string support in PDC_*clipboard() functions, and in Win32's
  PDC_set_title().

- Added the global string "ttytype", per other curses implementations,
  for compatibility with old BSD curses.

- Real functions for the "quasi-standard aliases" -- crmode(),
  nocrmode(), draino(), resetterm(), fixterm() and saveterm().
  (Corresponding macros removed.)

Bug fixes and such:

- In Win32, under NT-family OSes, the scrollback buffer would be
  restored by endwin(), but would not be turned off again when resuming
  curses after an endwin(). The result was an odd, partly-scrolled-up
  display. Now, the buffer is toggled by PDC_reset_prog_mode() and
  PDC_reset_shell_mode(), so it's properly turned off when returning
  from an endwin().

- In 3.0, selection in X11 didn't work. (Well, the selecting worked, but 
  the pasting elsewhere didn't.) This was due to the attempted fix 
  "don't return selection start as a press event," so that's been 
  reverted for now.

- PDC_setclipboard() was locking up in X11. Reported by Mark Hessling.

- Missing underscore in the declaration of XC_say() prevented
  compilation with PDCDEBUG defined.  Reported by M.H.

- Off-by-one error in copywin() -- the maximum coordinates for the
  destination window should be inclusive. Reported by Tiago Dionizio.

- Start in echo mode, per X/Open. Reported by T.D.

- Strip leading and trailing spaces from slk labels, per a literal
  reading of X/Open. Suggested by Alexey Miheev (about ncurses, but it
  also applies here).

- The #endif for __PDCURSES__ needs to come _after_ the closing of the
  extern "C". This has been broken since June 2005. Fortunately (?), it
  only shows up if the file is included multiple times, and then only in
  C++. Reported on the DOSBox forums.

- Use CF_OEMTEXT instead of CF_TEXT in the narrow versions of the 
  clipboard functions in Win32, to match the console.

- Changed the format of the string returned from longname().

- In the clipboard test in the testcurs demo, use a single mvprintw() to
  display the return from PDC_getclipboard(), instead of a loop of
  addch(), which was incompatible with multibyte strings.

- Moved has_key() into the keyname module, and documented it.

- Moved RIPPEDOFFLINE to curspriv.h.

- Typos in IMPLEMNT.

------------------------------------------------------------------------

PDCurses 3.0 - 2007/04/01
=========================

The focuses for this release are X/Open conformance, i18n, better color 
support, cleaner code, and more consistency across platforms.

This is only a brief summary of the changes. For more details, consult 
the CVS log.

New features:

- An almost complete implementation of X/Open curses, including the
  wide-character and attr_t functions (but excluding terminfo). The
  wide-character functions work only in Win32 and X11, for now, and
  require building the library with the appropriate options (see
  INSTALL). Note that this is a simplistic implementation, with exactly
  one wchar_t per cchar_t; the only characters it handles properly are
  those that are one column wide.

- Support for X Input Methods in the X11 port (see INSTALL). When built
  this way, the internal compose key support is disabled in favor of
  XIM's, which is a lot more complete, although you lose the box cursor.

- Multibyte character support in the non-wide string handling functions, 
  per X/Open. This only works when the library is built with wide- 
  character support enabled.

- Mouse support for DOS and OS/2. The DOS version includes untested 
  support for scroll wheels, via the "CuteMouse" driver.

- An ncurses-compatible mouse interface, which can work in parallel with 
  the traditional PDCurses mouse interface. See the man page (or 
  mouse.c) for details.

- DOS and OS/2 can now return modifiers as keys, as in Win32 and X11.

- COLORS, which had been fixed at 8, is now either 8 or 16, depending on
  the terminal -- usually 16. When it's 8, blinking mode is enabled
  (controlled as before by the A_BLINK attribute); when it's 16, bright
  background colors are used instead. On platforms where it can be
  changed, the mode is toggled by the new function PDC_set_blink().
  PDCurses tries to set PDC_set_blink(FALSE) at startup. (In Win32, it's
  always set to FALSE; in DOS, with other than an EGA or VGA card, it 
  can't be.) Also, COLORS is now set to 0 until start_color() is called.

- Corresponding to the change in COLORS, COLOR_PAIRS is now 256.

- Working init_color() and color_content(). The OS/2 version of
  init_color() works only in a full-screen session; the Win32 version
  works only in windowed mode, and only in NT-family OSes; the DOS
  version works only with VGA adapters (real or simulated). The Win32
  version is based mostly on James Brown's setconsoleinfo.c
  (www.catch22.net).

- use_default_colors(), assume_default_colors(), and curses_version(),
  after ncurses.

- Added global int TABSIZE, after ncurses and Solaris curses; removed
  window-specific _tabsize.

- Logical extension to the wide-character slk_ funcs: slk_wlabel(), for 
  retrieving the label as a wide-character string.

- A non-macro implementation of ncurses' wresize().

- Working putwin(), getwin(), scr_dump() and scr_restore().

- A working acs_map[]. Characters from the ACS are now stored in window
  structures as a regular character plus the A_ALTCHARSET attribute, and
  rendered to the ACS only when displayed. (This allows, for example,
  the correct display on one platform of windows saved from another.)

- In X11, allow selection and paste of UTF8_STRING.

- The testcurs demo now includes a color chart and init_color() test, a
  wide character input test, a display of wide ACS characters with
  sample Unicode text, a specific test of flash(), more info in the
  resize test, and attempts to change the width as well as the height.

- Command-line option for MSVC to build DLLs (see INSTALL). Also, the
  naming distinction for DLLs ("curses" vs. "pdcurses") is abandoned,
  and either the static lib or DLL is built, not both at once (except
  for X11).

- For backwards compatibility, a special module just for deprecated
  functions -- currently PDC_check_bios_key(), PDC_get_bios_key(),
  PDC_get_ctrl_break() and PDC_set_ctrl_break(). These shouldn't be used
  in applications, but currently are... in fact, all the "private"
  functions (in curspriv.h) are subject to change and should be avoided. 

- A new document, IMPLEMNT, describing PDCurses' internal functions for
  those wishing to port it to new platforms.

- Mark Hessling has released the X11 port to the public domain. 
  (However, x11/ScrollBox* retain their separate copyright and MIT-like 
  license.)

Bug fixes and such:

- Most of the macros have been removed (along with the NOMACROS ifdef).
  The only remaining ones are those which have to be macros to work, and
  those that are required by X/Open to be macros. There were numerous
  problems with the macros, and no apparent reason to keep them, except
  tradition -- although it was PCcurses 1.x that first omitted them.

- Clean separation of platform-specific code from the rest. Outside of
  the platform directories, there remain only a few ifdefs in curses.h
  and curspriv.h.

- General reorganization and simplification.

- Documentation revisions.

- When expanding control characters in addch() or insch(), retain the 
  attributes from the chtype.

- Preserve the A_ALTCHARSET attribute in addch() and insch().

- Per X/Open, beep() should always return OK.

- On platforms with a controlling terminal (i.e., not X11), curs_set(1)
  now sets the cursor to the shape it had at the time of initscr(),
  rather than always making it small. (Exception for DOS: If the video
  mode has been changed by PDC_resize_screen(), curs_set(1) reverts to
  line 6/7.) The shape is taken from SP->orig_cursor (the meaning of
  which is platform-specific).

- Stop updating the cursor position when the cursor is invisible (this 
  gives a huge performance boost in Win 9x); update the cursor position 
  from curs_set() if changing from invisible to visible.

- Some tweaking of the behavior of def_prog_mode(), def_shell_mode(), 
  savetty(), reset_prog_mode(), reset_shell_mode() and resetty()... 
  still not quite right.

- flash() was not implemented for Win32 or X. A portable implementation
  is now used for all platforms. Note that it's much slower than the
  old (DOS and OS/2) version, but this is only apparent on an extremely
  slow machine, such as an XT.

- In getstr(), backspacing on high-bit characters caused a double 
  backspace.

- hline() and vline() used an incorrect (off by one) interpretation of 
  _maxx and _maxy. If values of n greater than the max were specified, 
  these functions could access unallocated memory.

- innstr() is supposed to return the number of characters read, not just 
  OK or ERR. Reported by Mike Aubury.

- A proper implementation of insch() -- the PDC_chadd()-based version 
  wasn't handling the control characters correctly.

- Return ASCII and control key names from keyname() (problem revealed by
  ncurses' movewindow test); also, per X/Open, return "UNKNOWN KEY" when 
  appropriate, rather than "NO KEY NAME".

- Turn off the cursor from leaveok(TRUE), even in X11; leaveok(FALSE)
  now calls curs_set(1), regardless of the previous state of the cursor.

- In the slk area, BUTTON_CLICKED events now translate to function keys,
  along with the previously recognized BUTTON_PRESSED events. Of course,
  it should really be checking the events specified by map_button(),
  which still doesn't work.

- napms(0) now returns immediately.

- A unified napms() implementation for DOS -- no longer throttles the
  CPU when built with any compiler.

- Allow backspace editing of the nocbreak() buffer.

- pair_content(0, ...) is valid.

- There was no check to ensure that the pnoutrefresh() window fit within 
  the screen. It now returns an ERR if it doesn't.

- In X11, resize_term() must be called with parameters (0, 0), and only 
  when SP->resized is set, else it returns ERR.

- Copy _bkgd in resize_window(). Patch found on Frederic L. W. Meunier's 
  web site.

- slk_clear() now removes the buttons completely, as in ncurses.

- Use the current foreground color for the line attributes (underline,
  left, right), unless PDC_set_line_color() is explicitly called. After 
  setting the line color, you can reset it to this mode via 
  "PDC_set_line_color(-1)".

- Removed non-macro implementations of COLOR_PAIR() and PAIR_NUMBER().

- Dispensed with PDC_chadd() and PDC_chins() -- waddch() and winsch() 
  are now (again) the core functions.

- Dropped or made static many obsolete, unused, and/or broken functions,
  including PDC_chg_attrs(), PDC_cursor_on() and _off(),
  PDC_fix_cursor(), PDC_get_attribute(), PDC_get_cur_col() and _row(),
  PDC_set_80x25(), PDC_set_cursor_mode(), PDC_set_rows(),
  PDC_wunderline(), PDC_wleftline(), PDC_wrightline(),
  XCursesModifierPress() and XCurses_refresh_scrollbar().

- Obsolete/unused defines: _BCHAR, _GOCHAR, _STOPCHAR, _PRINTCHAR 
  _ENDLINE, _FULLWIN and _SCROLLWIN.

- Obsolete/unused elements of the WINDOW struct: _pmax*, _lastp*, 
  _lasts*.

- Obsolete/unused elements of the SCREEN struct: orgcbr, visible_cursor,
  sizeable, shell, blank, cursor, orig_emulation, font, orig_font,
  tahead, adapter, scrnmode, kbdinfo, direct_video, video_page,
  video_seg, video_ofs, bogus_adapter. (Some of these persist outside
  the SCREEN struct, in the platform directories.) Added mouse_wait and 
  key_code.

- Removed all the EMALLOC stuff. Straight malloc calls were used 
  elsewhere; it was undocumented outside of comments in curspriv.h; and 
  there are better ways to use a substitute malloc().

- Single mouse clicks are now reportable on all platforms (not just
  double-clicks). And in general, mouse event reporting is more
  consistent across platforms.

- The mouse cursor no longer appears in full-screen mode in Win32 unless
  a nonzero mouse event mask is used.

- ALT-keypad input now works in Win32.

- In Win32, SetConsoleMode(ENABLE_WINDOW_INPUT) is not useful, and 
  appears to be the source of a four-year-old bug report (hanging in 
  THE) by Phil Smith.

- Removed the PDC_THREAD_BUILD stuff, which has never worked. For the
  record: PDCurses is not thread-safe. Neither is ncurses; and the
  X/Open curses spec explicitly makes it a non-requirement.

- With the internal compose key system in the X11 port, modifier keys
  were breaking out of the compose state, making it impossible to type
  accented capitals, etc. Also, Multi_key is now the default compose
  key, instead of leaving it undefined by default; and a few more combos
  are supported.

- In X11, the first reported mouse event after startup always read as a
  double-click at position 0, 0. (This bug was introduced in 2.8.)

- In X11, don't return selection start as a press event. (Shift-click on
  button 1 is still returned.)

- In X11, properly handle pasting of high-bit chars. (It was doing an
  unwanted sign extension.)

- In X11, BUTTON_MOVED was never returned, although PDC_MOUSE_MOVED was
  set.

- The fix in 2.8 for the scroll wheel in X11 wasn't very good -- it did
  report the events as scroll wheel events, but it doubled them. Here's
  a proper fix.

- Changed mouse handling in X11: Simpler translation table, with
  XCursesPasteSelection() called from XCursesButton() instead of the
  translation table; require shift with button 1 or 2 for select or
  paste when mouse events are being reported (as with ncurses), allowing
  passthrough of simple button 2 events. This fixes the previously
  unreliable button 2 behavior.

- Modifier keys are now returned on key up in X11, as in Win32. And in
  general, modifier key reporting is more consistent across platforms.

- Modifiers are not returned as keys when a mouse click has occurred
  since the key press.

- In BIOS mode (in DOS), count successive identical output bytes, and
  make only one BIOS call for all of them. This dramatically improves 
  performance.

- The cursor position was not always updated correctly in BIOS mode.

- In testcurs, the way the ACS test was written, it would really only
  work with a) PDCurses (with any compiler), or b) gcc (with any
  curses). Here's a more portable implementation.

- Better reporting of mouse events in testcurs.

- Blank out buffer and num before the scanw() test in testcurs, in case 
  the user just hits enter or etc.; clear the screen after resizing.

- Allow tuidemo to use the last line.

- Separate left/right modifier keys are now reported properly in Win32.
  (Everything was being reported as _R.)

- Attempts to redirect input in Win32 now cause program exit and an 
  error message, instead of hanging.

- Dropped support for the Microway NDP compiler.

- Some modules renamed, rearranged.

- Fixes for errors and warnings when building with Visual C++ 2005.

- In MSVC, the panel library didn't work with the DLL.

- Complete export lists for DLLs.

- Simplified makefiles; moved common elements to .mif files; better 
  optimization; strip demos when possible.

- Changed makefile targets of "pdcurses.a/lib" and "panel.a/lib" to 
  $(LIBCURSES) and $(LIBPANEL). Suggestion of Doug Kaufman.

- Changed "install" target in the makefile to a double-colon rule, to 
  get around a conflict with INSTALL on non-case-sensitive filesystems, 
  such as Mac OS X's HFS+. Reported by Douglas Godfrey et al.

- Make PDCurses.man dependent on manext. Suggestion of Tiziano Mueller.

- Set up configure.ac so autoheader works; removed some obsolescent 
  macros. Partly the suggestion of T.M.

- The X11 port now builds in the x11 directory (including the demos), as
  with other ports.

- The X11 port should now build on more 64-bit systems. Partly due to 
  M.H.

- The default window title and icons for the X11 port are now "PDCurses"
  instead of "XCurses".

- Internal functions and variables made static where possible.

- Adopted a somewhat more consistent naming style: Internal functions
  with external linkage, and only those, have the prefix "PDC_";
  external variables that aren't part of the API use "pdc_"; static
  functions use "_"; and "XC_" and "xc_" prefixes are used for functions
  and variables, respectively, that are shared between both processes in
  the X11 port. Also eliminated camel casing, where possible.

- Changed the encoding for non-ASCII characters in comments and
  documentation from Latin-1 to UTF-8.

------------------------------------------------------------------------

PDCurses 2.8 - 2006/04/01
=========================

As with the previous version, you should assume that apps linked against 
older dynamic versions of the library won't work with this one until 
recompiled.

New features:

- Simpler, faster.

- Declarations for all supported, standard functions, per the X/Open
  Curses 4.2 spec, with the notable exception of getch() and ungetch().
  You can disable the use of the macro versions by defining NOMACROS
  before including curses.h (see xmas.c for an example). NOMACROS yields
  smaller but theoretically slower executables.

- New functions: vwprintw(), vwscanw(), vw_printw() and vw_scanw(). This 
  completes the list of X/Open 4.2 functions, except for those concerned 
  with attr_t and wide characters. Some (especially the terminfo/termcap 
  functions) aren't yet fully fleshed out, though.

- Non-macro implementations for COLOR_PAIR(), PAIR_NUMBER(), getbkgd(), 
  mvgetnstr(), mvwgetnstr(), mvhline(), mvvline(), mvwhline(), and 
  mvwvline(). (The macros are still available, too.)

- newterm() works now, in a limited way -- the parameters are ignored, 
  and only the first invocation will work (i.e., only one SCREEN can be 
  used).

- start_color() works now -- which is to say, if you _don't_ call it, 
  you'll only get monochrome output. Also, without calling it, the 
  terminal's default colors will be used, where supported (currently 
  only in Win32). This is equivalent to the PDC_ORIGINAL_COLORS behavior 
  introduced in 2.7, except that _only_ the default colors will be used. 
  (PDC_ORIGINAL_COLORS is still available, if you want to combine the 
  use of specific colors and the default colors.)

- New logic for termname() and longname(): termname() always returns
  "pdcurses"; longname() returns "PDCurses for [platform] [adapter]
  [COLOR/MONO]-YxX" (adapter is only defined for DOS and OS/2). This is
  the first time these functions return _anything_ in Win32.

- New installation method for XCurses: the header files are placed in a 
  subdirectory "xcurses" within the include directory, rather than being 
  renamed. (But the renamed xcurses.h and xpanel.h are also installed, 
  for backwards compatibility.) curspriv.h and term.h are now available,
  and existing curses-based code need no longer be edited to use 
  XCurses' curses.h. And with no more need for explicit XCursesExit() 
  calls (see below), your code need not be changed at all to move from 
  another curses implementation to XCurses. It can be as simple as "gcc 
  -I/usr/local/include/xcurses -lXCurses -oprogname progname.c".

- Combined readme.* into this HISTORY file, and incorporated the old 1.x
  (PCcurses) history.

- New functionality for the testcurs demo: ACS character display; menu 
  support for PgUp, PgDn, Home and End; centered menu; and it can now 
  be resized in X.

- Added modified versions of the rain and worm demos from ncurses.

Bug fixes and such:

- Big cleanup of dead and redundant code, including unneeded defines, 
  ifdefs, and structure elements.

- flushinp() was not implemented for Win32.

- resetty() was not restoring LINES and COLS.

- nonl() made '\n' print a line feed without carriage return. This was 
  incorrect.

- Removed bogus implementation of intrflush().

- The line-breakout optimization system, disabled by default in 2.7, is
  removed in 2.8. It simply didn't work, and never has. (The typeahead() 
  function remains, for compatibility, but does nothing.)

- The declarations for the printw() and scanw() function families were
  erroneously ifdef'd.

- Safer printw() calls on platforms that support vsnprintf().

- Use the native vsscanf() in DJGPP, MinGW and Cygwin.

- ACS_BLOCK now works in X.

- Explicit calls to XCursesExit() are no longer needed.

- XCURSES is now defined automatically if not DOS, OS2 or WIN32.

- The default icon for XCurses wasn't working (had to remove the focus 
  hint code to fix this). Also, the default title is now "XCurses" 
  instead of "main".

- Incorrect dimensions (undercounting by two in each direction) were
  shown while resizing in X.

- Scroll wheel events were not always correctly reported in X.

- 32 bits are enough for the "long" chtype, but 64 bits were used on a 
  64-bit system, wasting memory. Now conditioned on _LP64. This could be 
  faster, too.

- The short, 16-bit chtype now works with XCurses.

- Corrected return value for is_linetouched(), is_wintouched(),
  can_change_color() and isendwin() (bool instead of int).

- timeout(), wtimeout(), idcok() and immedok() return void.

- pair_content() takes a short.

- Replaced incorrect usages of attr_t with chtype. attr_t is still 
  typedef'd, for backwards compatibility. (It's supposed to be used for 
  the WA_*-style functions, which PDCurses doesn't yet support.)

- Added const where required by the spec, and in other appropriate
  places.

- Removed PDC_usleep(). napms() is now the core delay routine.

- Fixed poll() support in napms().

- Various changes to the internal PDC_* functions -- don't depend on 
  these, and don't use them unless you absolutely have to.

- Some routines accessed window structures in their variable 
  declarations, _before_ checking for a NULL window pointer.

- Dropped support for the undocumented PDC_FULL_DISPLAY, wtitle(), and
  PDC_print().

- Cleaned up remaining warnings.

- Reduced unnecessary #include directives -- speeds up compilation.

- Fix for demos build in Borland/DOS -- the makefile in 2.7 didn't 
  specify the memory model. Reported by Erwin Waterlander.

- Simplified the makefiles; e.g., some now build each demo in a single 
  step, and Watcom no longer uses demos.lnk. Also, the demo exes are now 
  stripped when possible; maximum compression used for archives built 
  by the makefiles; xcurses-config removed as part of "make distclean"; 
  and I tweaked optimization for some platforms.

- Reverted to /usr/local/ as default installation directory for XCurses.

- Upgraded to autoconf 2.59... instantly doubling the size of the
  configure script. Ah well. Otherwise, simplified the build system.

- Dropped support for pre-ANSI compilers. (It hasn't worked since at
  least version 2.4, anyway.)

- Revised and, I hope, clarified the boilerplate and other comments.

- Simplified logging and RCS ids; added RCS ids where missing.

- Consistent formatting for all code, approximately equivalent to
  "indent -kr -i8 -bl -bli0", with adjustments for 80 columns.

------------------------------------------------------------------------

PDCurses 2.7 - 2005/12/30
=========================

INTRODUCTION:

Hello all. As of a few weeks ago, I'm the new maintainer for PDCurses.
Here's a brief summary of changes in this release. (More details are
available in the CVS log and trackers on SourceForge.)

NEW FEATURES:

- Functions: delscreen(), getattrs(), has_key(), slk_color(),
  wcolor_set(), wtimeout().

- Macros: color_set(), mvhline(), mvvline(), mvwgetnstr(), mvwhline(),
  mvwvline(), timeout(), wresize().

- Stub implementations of terminfo functions (including a term.h).

- More stubs for compatibility: filter(), getwin(), putwin(),
  noqiflush(), qiflush(), scr_dump(), scr_init(), scr_restore(),
  scr_set(), use_env(), vidattr(), vidputs().

- The terminal's default colors are used as curses' default colors when
  the environment variable "PDC_ORIGINAL_COLORS" is set to any value
  (Win32 only at the moment).

- Simplified build system.

- Replaced PDC_STATIC_BUILD with its opposite, PDC_DLL_BUILD (see .mak
  files for more info).

- Minimal implementation of color_content() -- no longer a stub.

- Added the remaining ACS defines (ACS_S3, ACS_BBSS, etc.) for
  DOS/OS2/Win; "enhanced" versions of existing ACS characters used.

- Support for scroll wheels.

- Support for Pacific C.

BUGS FIXED:

- Builds correctly (including demos) on all tested platforms (see
  below); nearly all compiler warnings have been cleaned up; the ptest
  demo is built on all platforms; "clean" targets are improved.

- The ability to build ncurses_tests has been restored (see demos dir).

- Line-breakout optimization now defaults to off (equivalent to
  "typeahead(-1)"), so output is not interrupted by keystrokes (it's
  supposed to resume on the next refresh(), which wasn't working).

- Implicit wrefresh() in wgetch() was not being invoked in nodelay mode.

- subpad() was erroneously offsetting from the origin coordinates of the
  parent pad (which are always -1,-1).

- In wborder(), whline(), and wvline(), the current (wattrset) attribute
  was being used, but not the current background (wbkgd).

- Allow Russian 'r' character ASCII 0xe0 to be returned.

- termattrs() now also returns A_UNDERLINE, A_REVERSE.

- In Win32, with large scrollback buffers set, there was an unwanted
  "scrollup" effect on startup.

- Revamped keyboard handling for Win32.

- New screen resize method for Win32.

- napms(), delay_output(), etc. now work with Cygwin.

- curs_set(0) wasn't working in Win32 in full-screen (ALT-ENTER) mode --
  the cursor stayed on.

- The A_REVERSE attribute was broken in XCurses.

- On 64-bit systems, XCurses was ignoring every other keystroke.

- Added focus hints for XCurses.

- Demos (except for tuidemo) once again have their proper titles in
  XCurses (using Xinitscr() instead of the obsolete XCursesProgramName).

- The 16-bit chtype is a working option again (by removing #define
  CHTYPE_LONG from curses.h), except in XCurses. It's not recommended;
  but if your needs are limited, it still works.

- Reset screen size in resetty() under DOS, as in Win32 and OS/2.

- Changes for cursor size under DOS.

- Automatic setting of BIOS mode for CGA under DOS now works.

- The cursor is now always updated in PDC_gotoxy(); this fixes the
  problem of missing characters in BIOS mode.

- Macros nocbreak(), cbreak(), nocrmode(), crmode(), nodelay(),
  nl() and nonl() now return OK.

- ERR and OK are now defined as -1 and 0, respectively, for
  compatibility with other curses implementations -- note that this
  change is not binary compatible; you'll have to rebuild programs that
  use shared/dynamic libraries.

- Added "const" to prototypes where appropriate.

- Miscellaneous code cleanup.

ACKNOWLEDGEMENTS:

 - Walter Briscoe
 - Jean-Pierre Demailly
 - Ruslan Fedyarov
 - Warren Gay
 - Florian Grosse-Coosmann
 - Vladimir Kokovic
 - Matt Maloy
 - K.H. Man
 - Michael Ryazanov
 - Ron Thibodeau
 - Alexandr Zamaraev

and of course, MARK HESSLING, for his over 13 years of service as the
maintainer of PDCurses. Plus, thanks to all who've reported bugs or
requested features. Apologies to anyone I've forgotten.

I've tested this version on Turbo C++ 3.0 and Borland C++ 3.1 for DOS;
DJGPP 2.X; Open Watcom 1.3 for DOS (16 and 32-bit), Windows and OS/2;
EMX 0.9d and the "newgcc" version of EMX; Borland C++ 5.5 for Windows;
recent versions of MinGW, Cygwin, LCC-Win32 and Microsoft Visual C++;
and gcc under several flavors of Linux, Mac OS X, *BSD and Solaris.

-- William McBrine

------------------------------------------------------------------------

PDCurses 2.6 - 2003/01/08
=========================

INTRODUCTION:

 This release of PDCurses includes the following changes:

BUGS FIXED:

- Allow accented characters on Win32 platform when run on non-English
  keyboards.

- Allow "special" characters like Ctrl-S, Ctrl-Q under OS/2 to be returned.

- Some bugs with halfdelay() fixed by William McBrine.

- pechochar() should now work correctly.

- redrawwin() macro in curses.h was incorrect - fixed by Alberto Ornaghi

- Don't include "special" characters like KEY_SHIFT_L to be returned in
  getnstr() family. Bug 542913

- Entering TAB in wgetnstr() no longer exceeds requested buffer size.
  Bug 489233

- Fixed bug 550066, scrollok() and pads.
  Also beep() called when buffer exceeded. Bug 562041.

- Reverse video of X11 selection reinstated. Pablo Garcia Abio??

- Right Alt modifier now works like left Alt modifier under Win32

- Add support for all libXaw replacement libraries with Scrollbar bug. 
  Note that for this to work, you still have to change the libXaw 
  replacement libraries to fix the bug :-(

- Don't trap signals in XCurses if calling application has ignored them. 
  Change by Frank Heckenbach.

- Bug reports from Warren W. Gay:
  - Fix termattrs() to return A_REVERSE and A_BLINK on all platforms.
  - Fix definition of getsyx() and setsyx() to be consistent with 
    ncurses. Bug 624424.
  - Fix definition of echo() and noecho(). Bug 625001.
  - Fix definition of keypad() and leaveok(). Bug 632653.
  - Missing panel_hidden() prototype. Bug 649320.

- Fixed bug with calling def_prog_mode(), resize_term(), 
  reset_prog_mode(); the resize details were being lost.

NEW FEATURES:

- Clipboard support now available on DOS platform, but handled 
  internally to the currently running process.

- New X11 resource: textCursor, allows the text cursor to be specified 
  as a vertical bar, or the standard horizontal bar. Thanks to Frank 
  Heckenbach for the suggestion.

NEW COMPILER SUPPORT:

- lcc-win32 now works correctly

------------------------------------------------------------------------

PDCurses 2.5 - 2001/11/26
=========================

INTRODUCTION:

 This release of PDCurses includes the following changes:

- Set BASE address for Win32 DLL

- Add KEY_SUP and KEY_SDOWN.

- Add PDC_set_line_color()

- Add blink support as bold background

- Add bold colors

- Add getbkgd() macro

- Add new PDC functions for adding underline, overline, leftline and 
  rightline

- Add support for shifted keypad keys.

- Allow more keypad keys to work under Win32

- Change Win32 and OS/2 DLL name to curses.dll

- Change example resources to allow overriding from the command line

- Changes for building cleanly on OS/2

- Changes to handle building XCurses under AIX

- Check if prefresh() and pnoutrefresh() parameters are valid.

- Ensure build/install works from any directory

- Handle platforms where X11 headers do not typedef XPointer.

- Mention that Flexos is likely out-of-date.

- Pass delaytenths to XCurses_rawgetch()

- Remove boldFont

- Updates for cursor blinking and italic.

BUGS FIXED:

- Fix bug with getting Win32 clipboard contents. Added new 
  PDC_freeclipboard() function.

- Fix bug with halfdelay()

- Fix bug with mouse interrupting programs that are not trapping mouse 
  events under Win32.

- Fix return value from curs_set()

- Reverse the left and right pointing bars in ALT_CHARSET

NEW COMPILER SUPPORT:

- Add QNX-RTP port

------------------------------------------------------------------------

PDCurses 2.4 - 2000/01/17
=========================

INTRODUCTION:

 This release of PDCurses includes the following changes:

- full support of X11 selection handling

- removed the need for the cursos2.h file

- enabled the "shifted" key on the numeric keypad

- added native clipboard support for X11, Win32 and OS/2

- added extra functions for obtaining internal PDCurses status

- added clipboard and key modifier tests in testcurs.c

- fixes for panel library

- key modifiers pressed by themselves are now returned as keys:
  KEY_SHIFT_L KEY_SHIFT_R KEY_CONTROL_L KEY_CONTROL_R KEY_ALT_L KEY_ALT_R
  This works on Win32 and X11 ports only

- Added X11 shared library support

- Added extra slk formats supported by ncurses

- Fixed bug with resizing the terminal when slk were on.

- Changed behavior of slk_attrset(), slk_attron() slk_attroff()
  functions to work more like ncurses.

BUGS FIXED:

- some minor bug and portability fixes were included in this release

NEW FUNCTIONS:

- PDC_getclipboard() and PDC_setclipboard() for accessing the native
  clipboard (X11, Win32 and OS/2)

- PDC_set_title() for setting the title of the window (X11 and Win32 
  only)

- PDC_get_input_fd() for getting the file handle of the PDCurses input

- PDC_get_key_modifiers() for getting the keyboard modifier settings at 
  the time of the last (w)getch()

- Xinitscr() (only for X11 port) which allows standard X11 switches to 
  be passed to the application

NEW COMPILER SUPPORT:

- MingW32 GNU compiler under Win95/NT

- Cygnus Win32 GNU compiler under Win95/NT

- Borland C++ for OS/2 1.0+

- lcc-win32 compiler under Win95/NT

ACKNOWLEDGEMENTS: (for this release)

- Georg Fuchs for various changes.
- Juan David Palomar for pointing out getnstr() was not implemented.
- William McBrine for fix to allow black/black as valid color pair.
- Peter Preus for pointing out the missing bccos2.mak file.
- Laura Michaels for a couple of bug fixes and changes required to 
  support Mingw32 compiler.
- Frank Heckenbach for PDC_get_input_fd() and some portability fixes and
  the fixes for panel library.
- Matthias Burian for the lcc-win32 compiler support.

------------------------------------------------------------------------

PDCurses 2.3 - 1998/07/09
=========================

INTRODUCTION:

This release of PDCurses includes the following changes:

- added more System V R4 functions

- added Win32 port

- the X11 port is now fully functional

- the MS Visual C++ Win32 port now includes a DLL

- both the X11 and Win32 ports support the mouse

- the slk..() functions are now functional

- support for scrollbars under X11 are experimental at this stage

- long chtype extended to non-Unix ports

The name of the statically built library is pdcurses.lib (or 
pdcurses.a). The name of the DLL import library (where applicable) is 
curses.lib.

BUGS FIXED:

- some minor bugs were corrected in this release

NEW FUNCTIONS:

- slk..() functions

NEW COMPILER SUPPORT:

- MS Visual C++ under Win95/NT

- Watcom C++ under OS/2, Win32 and DOS

- two EMX ports have been provided:
  - OS/2 only using OS/2 APIs
  - OS/2 and DOS using EMX video support routines

EXTRA OPTIONS:

PDCurses recognizes two environment variables which determines the
initialization and finalization behavior.  These environment variables
do not apply to the X11 port.

PDC_PRESERVE_SCREEN -
If this environment variable is set, PDCurses will not clear the screen
to the default white on black on startup.  This allows you to overlay
a window over the top of the existing screen background.

PDC_RESTORE_SCREEN -
If this environment variable is set, PDCurses will take a copy of the
contents of the screen at the time that PDCurses is started; initscr(),
and when endwin() is called, the screen will be restored.


ACKNOWLEDGEMENTS: (for this release)

- Chris Szurgot for original Win32 port.
- Gurusamy Sarathy for some updates to the Win32 port.
- Kim Huron for the slk..() functions.
- Florian Grosse Coosmann for some bug fixes.
- Esa Peuha for reducing compiler warnings.
- Augustin Martin Domingo for patches to X11 port to enable accented 
  characters.

------------------------------------------------------------------------

PDCurses 2.2 - 1995/02/12
=========================

INTRODUCTION:

 This release of PDCurses has includes a number of major changes:

- The portable library functions are now grouped together into single 
  files with the same arrangement as System V R4 curses.

- A panels library has been included. This panels library was written by 
  Warren Tucker.

- Quite a few more functions have been supplied by Wade Schauer and 
  incorporated into release 2.2. Wade also supplied the support for the 
  Microway NDP C/C++ 32 bit DOS compiler.

- The curses datatype has been changed from an unsigned int to a long. 
  This allows more attributes to be stored as well as increasing the 
  number of color-pairs from 32 to 64.

- Xwindows port (experimental at the moment).

BUGS FIXED:

- mvwin() checked the wrong coordinates

- removed DESQview shadow memory buffer checking bug in curses.h in 
  \#define for wstandout()

- lots of others I can't remember

NEW FUNCTIONS:

- Too many to mention. See intro.man for a complete list of the 
  functions PDCurses now supports.

COMPILER SUPPORT:

- DJGPP 1.12 is now supported. The run-time error that caused programs 
  to crash has been removed.

- emx 0.9a is supported. A program compiled for OS/2 should also work 
  under DOS if you use the VID=EMX switch when compiling. See the 
  makefile for details.

- The Microway NDP C/C++ DOS compiler is now supported. Thanks to Wade 
  Schauer for this port.

- The Watcom C++ 10.0 DOS compiler is now supported. Thanks to Pieter 
  Kunst for this port.

- The library now has many functions grouped together to reduce the size 
  of the library and to improve the speed of compilation.

- The "names" of a couple of the compilers in the makefile has changed; 
  CSET2 is now ICC and GO32 is now GCC.

EXTRA OPTIONS:

 One difference between the behavior of PDCurses and Unix curses is the 
 attributes that are displayed when a character is cleared. Under Unix 
 curses, no attributes are displayed, so the result is always black. 
 Under PDCurses, these functions clear with the current attributes in 
 effect at the time. With the introduction of the bkgd functions, by 
 default, PDCurses clears using the value set by (w)bkgd(). To have 
 PDCurses behave the same way as it did before release 2.2, compile with 
 -DPDCURSES_WCLR

ACKNOWLEDGEMENTS: (for this release)

 Pieter Kunst, David Nugent, Warren Tucker, Darin Haugen, Stefan Strack, 
 Wade Schauer and others who either alerted me to bugs or supplied 
 fixes.

------------------------------------------------------------------------

PDCurses 2.1 - 1993/06/20
=========================

INTRODUCTION:

 The current code contains bug fixes for the DOS and OS/2 releases and 
 also includes an alpha release for Unix. The Unix release uses another 
 public domain package (mytinfo) to handle the low-level screen writes. 
 mytinfo was posted to comp.sources.unix (or misc) in December 1992 or 
 January 1993. Unless you are a glutton for punishment I would recommend 
 you avoid the Unix port at this stage.

 The other major addition to PDCurses is the support for DJGPP (the DOS 
 port of GNU C++). Thanks to David Nugent <davidn@csource.oz.au>.

 Other additions are copywin() function, function debugging support and 
 getting the small and medium memory models to work. The testcurs.c demo 
 program has also been changed significantly and a new demo program, 
 tuidemo, has been added.

 Some people have suggested including information on where to get dmake 
 from. oak.oakland.edu in /pub/msdos/c

OTHER NOTES:
	
 Under DOS, by default, screen writes to a CGA monitor are done via the 
 video BIOS rather than by direct video memory writes. This is due to 
 the CGA "snow" problem. If you have a CGA monitor and do not suffer 
 from snow, you can compile private\_queryad.c with CGA_DIRECT defined. 
 This will then use cause PDCurses to write directly to the CGA video 
 memory.

 Function debugging: Firstly to get function debugging, you have to 
 compile the library with OPT=N in the makefile. This also turns on 
 compiler debugging. You can control when you want PDCurses to write to 
 the debug file (called trace in the current directory) by using the 
 functions traceon() and traceoff() in your program.

 Microsoft C 6.00 Users note:
 ----------------------------

 With the addition of several new functions, using dmake to compile 
 PDCurses now causes the compiler to run "out of heap space in pass 2". 
 Using the 6.00AX version (DOS-Extended) to compile PDCurses fixes this 
 problem; hence the -EM switch.

 Functional changes
 ------------------

 Added OS/2 DLL support.

 A few curses functions have been fixed to exhibit their correct 
 behavior and make them more functionally portable with System V 
 curses. The functions that have changed are overlay(), overwrite() and 
 typeahead.

 overlay() and overwrite()

 Both of theses functions in PDCurses 2.0 allowed for one window to be 
 effectively placed on top of another, and the characters in the first 
 window were overlaid or overwritten starting at 0,0 in both windows. 
 This behavior of these functions was not correct. These functions only 
 operate on windows that physically overlap with respect to the 
 displayed screen. To achieve the same functionality as before, use the 
 new function copywin(). See the manual page for further details.

 typeahead()

 This function in PDCurses 2.0 effectively checked to see if there were 
 any characters remaining in the keyboard buffer. This is not the 
 behavior exhibited by System V curses. This function is intended 
 purely to set a flag so that curses can check while updating the 
 physical screen if any keyboard input is pending. To achieve the same 
 effect with typeahead() under PDCurses 2.1 the following code should be 
 used.

 In place of...

	while(!typeahead(stdin))
	 {
		/* do something until any key is pressed... */
	 }

 use...

	/* getch() to return ERR if no key pending */
	nodelay(stdscr,TRUE);
	while(getch() == (ERR))
	 {
		/* do something until any key is pressed... */
	 }


ACKNOWLEDGEMENTS: (in no particular order)

 Jason Shumate, Pieter Kunst, David Nugent, Andreas Otte, Pasi 
 Hamalainen, James McLennan, Duane Paulson, Ib Hojme
	
 Apologies to anyone I may have left out.

------------------------------------------------------------------------

PDCurses 2.0 - 1992/11/23
=========================

INTRODUCTION:

 Well, here it finally is; PDCurses v2.0.

 PDCurses v2.0 is an almost total rewrite of PCcurses 1.4 done by John 
 'Frotz' Fa'atuai, the previous maintainer. It adds support for OS/2 as 
 well as DOS.

 This version has been tested with Microsoft C v6.0, QuickC v2.0 and 
 Borland C++ 2.0 under DOS and Microsoft C v6.0 and TopSpeed c v3.02 
 under OS/2 2.0. Also the library has been compiled successfully with 
 emx 0.8e, C Set/2 and Watcom 9. Most testing was done with the large 
 memory model, where applicable. The large memory model is probably the 
 best model to use.

 The amount of testing has not been as extensive as I would have liked, 
 but demands on releasing a product have outweighed the product's 
 quality. Nothing new with that !! Hopefully with wider circulation, 
 more bugs will be fixed more quickly.

 I have included just 1 makefile which is suitable for dmake 3.8 for 
 both DOS and OS/2. The makefile does not rely on customization of the 
 dmake.ini file.

 If you discover bugs, and especially if you have fixes, please let me 
 know ASAP.

 The source to the library is distributed as a zip file made with zip 
 1.9. You will need Info-ZIP unzip 5.0 to unzip. Follow the directions 
 below to compile the library.

DIRECTIONS:

 1. Create a new directory in which to unzip pdcurs20.zip. This will 
    create a curses directory and a number of subdirectories containing 
    source code for the library and utilities and the documentation.

 2. Make changes to the makefile where necessary:
    Change the MODEL or model macro to the appropriate value (if it
    applies to your compiler). Use model for Borland compilers.

    Change any paths in the defined macros to be suitable for your
    compiler.

 3. Invoke DMAKE [-e environment_options] [target]

    where environment_options are:

        OS (host operating system)
        COMP (compiler)
        OPT (optimized version or debug version) - optional. default Y
        TOS (target operating system) - optional. default OS

    see the makefile for valid combinations

    targets: all, demos, lcursesd.lib, manual...
	
    NB. dmake is case sensitive with targets, so those environments that 
    use an upper case model value (eg MSC) MUST specify the library 
    target as for eg. Lcursesd.lib

    The makefile is by default set up for Borland C++. The use of -e 
    environment_options override these defaults. If you prefer, you can 
    just change the defaults in the makefile and invoke it without the 
    -e switch.

OTHER NOTES:

 The documentation for the library is built into each source file, a 
 couple of specific doc files and the header files. A program is 
 supplied (manext) to build the manual. This program gets compiled when 
 you build the documentation.
	
 To generate the library response file correctly, I had to write a quick 
 and dirty program (buildlrf) to achieve this. Originally the makefiles 
 just had statements like: "echo -+$(OBJ)\$* & >> $(LRF)" which appended 
 a suitable line to the response file. Unfortunately under some 
 combinations of makefiles and command processors (eg. nmake and 4DOS) 
 the & would get treated as stderr and the echo command would fail.
	
 The original source for PDCurses that I received from the previous 
 maintainer contained support for the FLEXOS operating system. Not 
 having access to it, I could not test the changes I made so its support 
 has fallen by the wayside. If you really need to have PDCurses running 
 under FLEXOS, contact me and I will see what can be arranged.
	
 Under DOS, by default, screen writes to a CGA monitor are done via the 
 video BIOS rather than by direct video memory writes. This is due to 
 the CGA "snow" problem. If you have a CGA monitor and do not suffer 
 from snow, you can compile private\_queryad.c with CGA_DIRECT defined. 
 This will then use cause PDCurses to write directly to the CGA video 
 memory.

 Added System V color support.

COMPILER-SPECIFIC NOTES:

 Microsoft C
 -----------

 It is possible with MSC 6.0 to build the OS/2 libraries and demo 
 programs from within DOS. This is the only case where it is possible to 
 specify the value of TOS on the command line to be OS2 and the value of 
 OS be DOS.

 C Set/2
 -------

 I have only tested the library using the migration libraries. I doubt 
 that the demo programs will work without them.

 emx
 ---

 Testing has been done with 0.8e of emx together with the 16_to_32 
 libraries. The emx\lib directory should include the vio32.lib and 
 kbd32.lib libraries from the 16_to_32 package.

BUGS and UNFINISHED BUSINESS:

- PDC_set_ctrl_break() function does not work under OS/2.

- win_print() and PDC_print() do not work under OS/2.

- The file todo.man in the doc directory also lists those functions of 
  System V 3.2 curses not yet implemented. Any volunteers?

ACKNOWLEDGEMENTS:

- John 'Frotz' Fa'atuai, the previous maintainer for providing an
  excellent base for further development.
- John Burnell <johnb@kea.am.dsir.govt.nz>, for the OS/2 port.
- John Steele, Jason (finally NOT a John) Shumate....
  for various fixes and suggestions.
- Eberhardt Mattes (author of emx) for allowing code based on his
  C library to be included with PDCurses.
- Several others for their support, moral and actual.

-- Mark Hessling

------------------------------------------------------------------------

PDCurses 2.0Beta - 1991/12/21
=============================

Changed back from short to int. (int is the correct size for the default 
platform. Short might be too short on some platforms. This is more 
portable. I, also, made this mistake.)

Many functions are now macros.  If you want the real thing, #undef the 
macro. (X/Open requirement.)

Merged many sources into current release.

Added many X/Open routines (not quite all yet).

Added internal documentation to all routines.

Added a HISTORY file to the environment.

Added a CONTRIB file to the environment.

------------------------------------------------------------------------

PDCurses 1.5Beta - 1990/07/14
=============================

Added many levels of compiler support. Added mixed prototypes for all 
"internal" routines. Removed all assembly language.  Added EGA/VGA 
support.  Converted all #ifdef to #if in all modules except CURSES.H and 
CURSPRIV.H. Always include ASSERT.H.  Added support for an external 
malloc(), calloc() and free(). Added support for FAST_VIDEO 
(direct-memory writes). Added various memory model support (for 
FAST_VIDEO). Added much of the December 1988 X/Open Curses 
specification.

-- John 'Frotz' Fa'atuai

------------------------------------------------------------------------

PCcurses 1.4 - 1990/01/14
=========================

  In PCcurses v.1.4, both portability improvements and bugfixes have 
been made. The files have been changed to allow lint-free compilation 
with Microsoft C v.5.1, and with Turbo C v.2.0. The source should still 
compile without problems on older compilers, although this has not been 
verified.

  The makefiles have been changed to suit both the public release and 
the author, who maintains a special kind of libraries for himself. In 
the case of Microsoft C, changes were done in the makefile to lower the 
warning level to 2 (was 3). This was to avoid ANSI warnings which are 
abundant because PCcurses does not attempt to follow strict ANSI C 
standard.

  BUG FIXES FROM V.1.3 TO V.1.4:

  !!!IMPORTANT CHANGE!!!

  The definitions for OK and ERR in curses.h were exchanged. This was 
done to be more consistent with UNIX versions. Also, it permits 
functions like newwin() and subwin() to return 0 (=NULL) when they fail 
due to memory shortage. This incompatibility with UNIX curses was 
pointed out by Fred C. Smith. If you have tested success/failure by 
comparisons to anything other than ERR and OK, your applications will 
need to be be changed on that point. Sorry... but presumably most of you 
used the symbolic constants?

  (END OF IMPORTANT CHANGE)

  Fred also pointed out a bug in the file update.c. The bug caused the 
first character printed after 'unauthorized' screen changes (like during 
a shell escape, for example) to be placed at the wrong screen position. 
This happened even if the normal precautions (clear / touch / refresh) 
were taken. The problem has now been fixed.

  PCcurses is currently also being used on a 68000 system with 
hard-coded ESCape sequences for ANSI terminals. However, ints used by 
the 68000 C compiler are 32 bits. Therefore ints have been turned into 
shorts wherever possible in the code (otherwise all window structures 
occupy twice as much space as required on the 68000). This does not 
affect PC versions since normally both ints and shorts are 16 bits for 
PC C compilers.

  At some places in the source code there are references made to the 
68000 version. There are also a makefile, a curses68.c file, and a 
curses68.cmd file. These are for making, low-level I/O, and linking 
commands when building the 68000 version. These files are probably 
useful to no-one but the author, since it is very specific for its 
special hardware environment. Still in an effort to keep all 
curses-related sources in one place they are included. Note however that 
PCcurses will not officially support a non-PC environment.

  The file cursesio.c, which was included in the package at revision 
level 1.2, and which was to be an alternative to the cursesio.asm file, 
has been verified to behave incorrectly in the function _curseskeytst(). 
The problem was that the value of 'cflag' does not contain the proper 
data for the test that is attempted. Furthermore, neither Turbo C or 
Microsoft C allows any way to return the data that is needed, and 
consequently you should not use cursesio.c. The best solution is to 
simply use the ASM version. In v.1.2 and v.1.3, the user could edit the 
makefile to select which version he wanted to use. The makefiles in 
v.1.4 have removed this possibility forcing the use of the ASM file, and 
cursesio.c has been dropped from the distribution.

  A bug in the wgetstr() function caused PCcurses to echo characters 
when reading a keyboard string, even if the echo had been turned off. 
Thanks to Per Foreby at Lund University, Sweden, for this. Per also 
reported bugs concerning the handling of characters with bit 8 set. 
Their ASCII code were considered as lower than 32, so they were erased 
etc. like control characters, i.e. erasing two character positions. The 
control character test was changed to cope with this.

  The overlay() and overwrite() functions were changed so that the 
overlaying window is positioned at its 'own' coordinates inside the 
underlying window (it used to be at the underlying window's [0,0] 
position). There is some controversy about this - the documentation for 
different curses versions say different things. I think the choice made 
is the most reasonable.

  The border() and wborder() functions were changed to actually draw a 
border, since this seems to be the correct behavior of these functions. 
They used to just set the border characters to be used by box(). These 
functions are not present in standard BSD UNIX curses.

  The subwin() function previously did not allow the subwindow to be as 
big as the original window in which it was created. This has now been 
fixed. There was also the problem that the default size (set by 
specifying numlines or numcols (or both) as 0 made the resulting actual 
size 1 line/column too small.

  There were a few spelling errors in function names, both in the 
function declarations and in curses.h. This was reported by Carlos 
Amaral at INESC in Portugal. Thanks! There was also an unnecessary (but 
harmless) parameter in a function call at one place.

------------------------------------------------------------------------

PCcurses 1.3 - 1988/10/05
=========================

  The file 'border.c' is now included. It allows you to explicitly 
specify what characters should be used as box borders when the box() 
functions are called. If the new border characters are non-0, they 
override the border characters specified in the box() call. In my 
understanding, this functionality is required for AT&T UNIX sV.3 
compatibility. Thanks for this goes to Tony L. Hansen
(hansen@pegasus.UUCP) for posting an article about it on Usenet 
(newsgroup comp.unix.questions; his posting was not related at all to 
PCcurses).

  The only other difference between v.1.2 and v.1.3 is that the latter 
has been changed to avoid warning diagnostics if the source files are 
compiled with warning switches on (for Microsoft this means '-W3', for 
Turbo C it means '-w -w-pro'). Of these, the Turbo C warning check is 
clearly to be used rather than Microsoft, even if neither of them comes 
even close to a real UNIX 'lint'. Some of the warnings in fact indicated 
real bugs, mostly functions that did not return correct return values or 
types.

  The makefiles for both MSC and TRC have been modified to produce 
warning messages as part of normal compilation.

------------------------------------------------------------------------

PCcurses 1.2 - 1988/10/02
=========================

  The changes from v.1.1 to v.1.2 are minor. The biggest change is that 
there was a bug related to limiting the cursor movement if the 
application tried to move it outside the screen (something that should 
not be done anyway). Such erroneous application behavior is now handled 
appropriately.

  All modules have been changed to have a revision string in them, which 
makes it easier to determine what version is linked into a program (or 
what library version you have).

  There is now a 'cursesio.c' file. That file does the same as 
'cursesio.asm' (i.e. it provides the interface to the lower-level system 
I/O routines). It is written in C and thus it is (possibly) more 
portable than the assembler version (but still not so portable since it 
uses 8086 INT XX calls directly). When one creates new curses libraries, 
one chooses whether to use the assembler or the C version of cursesio. 
The choice is made by commenting out the appropriate dependencies for 
cursesio.obj, near the end of the makefiles.

  There is now a 'setmode.c' file. That file contains functions that 
save and restore terminal modes. They do it into other variables than do 
savetty() and resetty(), so one should probably use either 
savetty()/resetty() or the new functions only - and not mix the both 
ways unless one really knows what one does.

  Diff lists vs v.1.0 are no longer included in the distribution. The 
make utility still is. PCcurses v.1.2 still compiles with Microsoft C 
v.4.0, and with Borland Turbo C v.1.0. There is as far as I know no 
reason to believe that it does not compile under Microsoft C v.3.0 and 
5.x, or Turbo C v.1.5, but this has not been tested.

  There are two makefiles included, one for Microsoft C, one for Turbo 
C. They are both copies of my personal makefiles, and as such they 
reflect the directory structure on my own computer. This will have to be 
changed before you run make. Check $(INCDIR) and $(LIBDIR) in 
particular, and make the choice of ASM or C cursesio version as 
mentioned above (the distribution version uses the C version of 
cursesio).

  The manual file (curses.man) has been changed at appropriate places.

  I would like to thank the following persons for their help:

  	Brandon S. Allbery (alberry@ncoast.UUCP)
		for running comp.binaries.ibm.pc (at that time)
		and comp.source.misc.

	Steve Balogh (Steve@cit5.cit.oz.AU)
  		for writing a set of manual pages and posting
		them to the net.

	Torbjorn Lindh
		for finding bugs and suggesting raw
		character output routines.

	Nathan Glasser (nathan@eddie.mit.edu)
  		for finding and reporting bugs.

	Ingvar Olafsson (...enea!hafro!ingvar)
  		for finding and reporting bugs.

	Eric Rosco (...enea!ipmoea!ericr)
  		for finding and reporting bugs.

	Steve Creps (creps@silver.bacs.indiana.edu)
  		for doing a lot of work - among others
		posting bug fixes to the net, and writing
		the new cursesio.c module.

	N. Dean Pentcheff (dean@violet.berkeley.edu)
  		for finding bugs and rewriting cursesio.asm
		for Turbo 'C' 1.5.

  Finally, Jeff Dean (parcvax,hplabs}!cdp!jeff)
  		     (jeff@ads.arpa)
	has had a shareware version of curses deliverable since
	about half a year before I released PCcurses 1.0 on Use-
	Net. He is very concerned about confusion between the two
	packages, and therefore any references on the network
	should make clear whether they reference Dean's PCcurses
	or Larsson's PCcurses.

------------------------------------------------------------------------

PCcurses 1.1 - 1988/03/06
=========================

  The changes from v.1.0 to v.1.1 are minor. There are a few bug fixes, 
and new (non-portable) functions for verbatim IBM character font display 
have been added (in charadd.c and charins.c). The manual file 
(curses.man) has been changed at appropriate places.

  In the file v10tov11.dif there are listings of the differences between
version 1.0 and 1.1. The diff listings are in UNIX diff(1) format.

  Version 1.1 compiles with Turbo C v.1.0, as well as Microsoft C v.3.0 
and v.4.0. On the release disk there is a make.exe utility which is very 
similar to UNIX make (If the package was mailed to you, the make utility 
will be in uuencoded format - in make.uu - and must be uudecoded first). 
It is much more powerful than Microsoft's different MAKEs; the latter 
ones will NOT generate libraries properly if used with the PCcurses 
makefiles.

  There are three makefiles:

	makefile		generic MSC 3.0 makefile
	makefile.ms		MSC 4.0 makefile
	makefile.tc		Turbo C 1.0 makefile

  To make a library with for example Turbo C, make directories to hold 
.H and .LIB files (these directories are the 'standard places'), edit 
makefile.tc for this, and type

	make -f makefile.tc all

and libraries for all memory models will be created in the .LIB 
directory, while the include files will end up in the .H directory. Also 
read what is said about installation below!

------------------------------------------------------------------------

PCcurses 1.0 - 1987/08/24
=========================

  This is the release notes for the PCcurses v.1.0 cursor/window control 
package. PCcurses offers the functionality of UNIX curses, plus some 
extras. Normally it should be possible to port curses-based programs 
from UNIX curses to PCcurses on the IBM PC without changes. PCcurses is 
a port/ rewrite of Pavel Curtis' public domain 'ncurses' package. All 
the code has been re-written - it is not just an edit of ncurses (or 
UNIX curses). I mention this to clarify any copyright violation claims. 
The data structures and ideas are very similar to ncurses. As for UNIX 
curses, I have not even seen any sources for it.

  For an introduction to the use of 'curses' and its derivatives, you 
should read 'Screen Updating and Cursor Movement Optimization: A Library 
Package' by Kenneth C. R. C. Arnold, which describes the original 
Berkeley UNIX version of curses. It is available as part of the UNIX 
manuals. The other source of information is 'The Ncurses Reference 
Manual' by Pavel Curtis. The latter is part of Curtis' ncurses package.

  The only other documentation provided is a 'man' page which describes 
all the included functions in a very terse way. In the sources, each 
function is preceded by a rather thorough description of what the 
function does. I didn't have time to write a nice manual/tutorial - 
sorry.

  PCcurses is released as a number of source files, a man page, and a 
make file. A uuencoded copy of a 'make' utility, and a manpage for the 
'make' is also provided to make it easier to put together PCcurses 
libraries. Even if you are not interested in PCcurses, it may be 
worthwhile to grab the make.

  The makefile assumes the presence of the Microsoft C compiler (3.0 or 
4.0), Microsoft MASM and LIB, plus some MS-DOS utilities. The reason for 
supplying MAKE.EXE is that the Microsoft 'MAKE:s' are much inferior to a 
real UNIX make. The supplied make is a port of a public domain make, 
published on Usenet. It is almost completely compatible with UNIX make. 
When generating the curses libraries, the makefile will direct make to 
do some directory creating and file copying, and then re-invoke itself 
with new targets. The workings of the makefile are not absolutely 
crystal clear at first sight... just start it and see what it does.

  For portability, the curses libraries depend on one assembler file for 
access to the BIOS routines. There is no support for the EGA, but both 
CGA, MGA, and the HGA can be used. The libraries are originally for 
Microsoft C, but all C modules should be portable right away. In the 
assembler file, segment names probably need to be changed, and possibly 
the parameter passing scheme. I think Turbo C will work right away - as 
far as I understand, all its conventions are compatible with Microsoft 
C.

  There are some parts left out between ncurses and PCcurses. One is the 
support for multiple terminals - not very interesting on a PC anyway. 
Because we KNOW what terminal we have, there is no need for a termcap or 
terminfo library. PCcurses also has some things that neither curses nor 
ncurses have. Compared to the original UNIX curses, PCcurses has lots of 
extras.

  The BIOS routines are used directly, which gives fast screen updates.
PCcurses does not do direct writes to screen RAM - in my opinion it is
a bit ugly to rely that much on hardware compatibility. Anyone could fix
that, of course...

  One of the more serious problems with PCcurses is the way in which 
normal, cbreak, and raw input modes are done. All those details are in 
the 'charget' module - I do raw I/O via the BIOS, and perform any 
buffering myself. If an application program uses PCcurses, it should do 
ALL its I/O via PCcurses calls, otherwise the mix of normal and 
PCcurses I/O may mess up the display. I think my code is reasonable... 
comments are welcome, provided you express them nicely...

  To install, copy all files to a work directory, edit 'makefile' to 
define the standard include and library file directory names of your 
choice (these directories must exist already, and their path names must 
be relative to the root directory, not to the current one). You must 
also run uudecode on make.uu, to generate MAKE.EXE. You can do that on 
your PC, if you have uudecode there, otherwise you can do it under UNIX 
and do a binary transfer to the PC. When you have MAKE.EXE in your work 
directory (or in your /bin directory), type make.

  Make will now create 4 sub-directories (one for each memory model), 
copy some assembler include files into them, copy two include files to 
your include directory, CHDIR to each sub-directory and re-invoke itself 
with other make targets to compile and assemble all the source files 
into the appropriate directories. Then the library manager is run to 
create the library files in your desired library directory. Presto!

  If you only want to generate a library for one memory model, type 
'make small', 'make large', etc. The name of the memory model must be in 
lower case, like in the makefile.

  I think the package is fairly well debugged - but then again, that's 
what I always think. It was completed in May-87, and no problems found 
yet. Now it's your turn... Comments, suggestions and bug reports and 
fixes (no flames please) to

-- Bjorn Larsson
