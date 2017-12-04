/* Public Domain Curses */

#include "pdcwin.h"

#include <stdlib.h>
#include <string.h>

#ifdef CHTYPE_LONG

# define A(x) ((chtype)x | A_ALTCHARSET)

chtype acs_map[128] =
{
    A(0), A(1), A(2), A(3), A(4), A(5), A(6), A(7), A(8), A(9), A(10),
    A(11), A(12), A(13), A(14), A(15), A(16), A(17), A(18), A(19),
    A(20), A(21), A(22), A(23), A(24), A(25), A(26), A(27), A(28), 
    A(29), A(30), A(31), ' ', '!', '"', '#', '$', '%', '&', '\'', '(', 
    ')', '*',

# ifdef PDC_WIDE
    0x2192, 0x2190, 0x2191, 0x2193,
# else
    A(0x1a), A(0x1b), A(0x18), A(0x19),
# endif

    '/',

# ifdef PDC_WIDE
    0x2588,
# else
    0xdb,
# endif

    '1', '2', '3', '4', '5', '6', '7', '8', '9', ':', ';', '<', '=',
    '>', '?', '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
    'X', 'Y', 'Z', '[', '\\', ']', '^', '_',

# ifdef PDC_WIDE
    0x2666, 0x2592,
# else
    A(0x04), 0xb1,
# endif

    'b', 'c', 'd', 'e',

# ifdef PDC_WIDE
    0x00b0, 0x00b1, 0x2591, 0x00a4, 0x2518, 0x2510, 0x250c, 0x2514,
    0x253c, 0x23ba, 0x23bb, 0x2500, 0x23bc, 0x23bd, 0x251c, 0x2524,
    0x2534, 0x252c, 0x2502, 0x2264, 0x2265, 0x03c0, 0x2260, 0x00a3,
    0x00b7,
# else
    0xf8, 0xf1, 0xb0, A(0x0f), 0xd9, 0xbf, 0xda, 0xc0, 0xc5, 0x2d, 0x2d,
    0xc4, 0x2d, 0x5f, 0xc3, 0xb4, 0xc1, 0xc2, 0xb3, 0xf3, 0xf2, 0xe3,
    0xd8, 0x9c, 0xf9,
# endif

    A(127)
};

# undef A

#endif

/* position hardware cursor at (y, x) */

void PDC_gotoyx(int row, int col)
{
    COORD coord;

    PDC_LOG(("PDC_gotoyx() - called: row %d col %d from row %d col %d\n",
             row, col, SP->cursrow, SP->curscol));

    coord.X = col;
    coord.Y = row;

    SetConsoleCursorPosition(pdc_con_out, coord);
}

/* update the given physical line to look like the corresponding line in
   curscr */

void PDC_transform_line(int lineno, int x, int len, const chtype *srcp)
{
    CHAR_INFO ci[512];
    int j;
    COORD bufSize, bufPos;
    SMALL_RECT sr;

    PDC_LOG(("PDC_transform_line() - called: lineno=%d\n", lineno));

    bufPos.X = bufPos.Y = 0;

    bufSize.X = len;
    bufSize.Y = 1;

    sr.Top = lineno;
    sr.Bottom = lineno;
    sr.Left = x;
    sr.Right = x + len - 1;

    for (j = 0; j < len; j++)
    {
        chtype ch = srcp[j];

        ci[j].Attributes = pdc_atrtab[ch >> PDC_ATTR_SHIFT];
#ifdef CHTYPE_LONG
        if (ch & A_ALTCHARSET && !(ch & 0xff80))
            ch = acs_map[ch & 0x7f];
#endif
        ci[j].Char.UnicodeChar = ch & A_CHARTEXT;
    }

    WriteConsoleOutput(pdc_con_out, ci, bufSize, bufPos, &sr);
}
