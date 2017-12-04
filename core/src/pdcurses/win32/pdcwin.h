/* Public Domain Curses */

#ifdef PDC_WIDE
# define UNICODE
#endif

#include <windows.h>
#undef MOUSE_MOVED
#include <curspriv.h>

#ifdef CHTYPE_LONG
# define PDC_ATTR_SHIFT 19
#else
# define PDC_ATTR_SHIFT 8
#endif

#if (defined(__CYGWIN32__) || defined(__MINGW32__) || defined(__WATCOMC__) || defined(_MSC_VER)) && \
    !defined(HAVE_INFOEX)
# define HAVE_INFOEX
#endif

extern unsigned char *pdc_atrtab;
extern HANDLE pdc_con_out, pdc_con_in;
extern DWORD pdc_quick_edit;

extern int PDC_get_buffer_rows(void);
