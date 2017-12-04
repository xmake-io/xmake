/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

overlay
-------

### Synopsis

    int overlay(const WINDOW *src_w, WINDOW *dst_w)
    int overwrite(const WINDOW *src_w, WINDOW *dst_w)
    int copywin(const WINDOW *src_w, WINDOW *dst_w, int src_tr,
    int src_tc, int dst_tr, int dst_tc, int dst_br,
    int dst_bc, bool overlay)

### Description

   overlay() and overwrite() copy all the text from src_w into
   dst_w. The windows need not be the same size. Those characters
   in the source window that intersect with the destination window
   are copied, so that the characters appear in the same physical
   position on the screen. The difference between the two functions
   is that overlay() is non-destructive (blanks are not copied)
   while overwrite() is destructive (blanks are copied).

   copywin() is similar, but doesn't require that the two windows
   overlap. The arguments src_tc and src_tr specify the top left
   corner of the region to be copied. dst_tc, dst_tr, dst_br, and
   dst_bc specify the region within the destination window to copy
   to. The argument "overlay", if TRUE, indicates that the copy is
   done non-destructively (as in overlay()); blanks in the source
   window are not copied to the destination window. When overlay is
   FALSE, blanks are copied.

### Return Value

   All functions return OK on success and ERR on error.

### Portability
                             X/Open    BSD    SYS V
    overlay                     Y       Y       Y
    overwrite                   Y       Y       Y
    copywin                     Y       -      3.0

**man-end****************************************************************/

/* Thanks to Andreas Otte <venn@@uni-paderborn.de> for the 
   corrected overlay()/overwrite() behavior. */

static int _copy_win(const WINDOW *src_w, WINDOW *dst_w, int src_tr,
                     int src_tc, int src_br, int src_bc, int dst_tr,
                     int dst_tc, bool _overlay)
{
    int col, line, y1, fc, *minchng, *maxchng;
    chtype *w1ptr, *w2ptr;

    int lc = 0;
    int xdiff = src_bc - src_tc;
    int ydiff = src_br - src_tr;

    if (!src_w || !dst_w)
        return ERR;

    minchng = dst_w->_firstch;
    maxchng = dst_w->_lastch;

    for (y1 = 0; y1 < dst_tr; y1++)
    {
        minchng++;
        maxchng++;
    }

    for (line = 0; line < ydiff; line++)
    {
        w1ptr = src_w->_y[line + src_tr] + src_tc;
        w2ptr = dst_w->_y[line + dst_tr] + dst_tc;

        fc = _NO_CHANGE;

        for (col = 0; col < xdiff; col++)
        {
            if ((*w1ptr) != (*w2ptr) &&
                !((*w1ptr & A_CHARTEXT) == ' ' && _overlay))
            {
                *w2ptr = *w1ptr;

                if (fc == _NO_CHANGE)
                    fc = col + dst_tc;
            
                lc = col + dst_tc;
            }

            w1ptr++;
            w2ptr++;
        }

        if (*minchng == _NO_CHANGE)
        {
            *minchng = fc;
            *maxchng = lc;
        }
        else if (fc != _NO_CHANGE)
        {
            if (fc < *minchng)
                *minchng = fc;
            if (lc > *maxchng)
                *maxchng = lc;
        }

        minchng++;
        maxchng++;
    }

    return OK;
}

int _copy_overlap(const WINDOW *src_w, WINDOW *dst_w, bool overlay)
{
    int first_line, first_col, last_line, last_col;
    int src_start_x, src_start_y, dst_start_x, dst_start_y;
    int xdiff, ydiff;

    if (!src_w || !dst_w)
        return ERR;

    first_col = max(dst_w->_begx, src_w->_begx);
    first_line = max(dst_w->_begy, src_w->_begy);

    last_col = min(src_w->_begx + src_w->_maxx, dst_w->_begx + dst_w->_maxx);
    last_line = min(src_w->_begy + src_w->_maxy, dst_w->_begy + dst_w->_maxy);

    /* determine the overlapping region of the two windows in real 
       coordinates */

    /* if no overlapping region, do nothing */

    if ((last_col < first_col) || (last_line < first_line))
        return OK;

    /* size of overlapping region */

    xdiff = last_col - first_col;
    ydiff = last_line - first_line;

    if (src_w->_begx <= dst_w->_begx)
    {
        src_start_x = dst_w->_begx - src_w->_begx;
        dst_start_x = 0;
    }
    else
    {
        dst_start_x = src_w->_begx - dst_w->_begx;
        src_start_x = 0;
    }

    if (src_w->_begy <= dst_w->_begy)
    {
        src_start_y = dst_w->_begy - src_w->_begy;
        dst_start_y = 0;
    }
    else
    {
        dst_start_y = src_w->_begy - dst_w->_begy;
        src_start_y = 0;
    }

    return _copy_win(src_w, dst_w, src_start_y, src_start_x,
                     src_start_y + ydiff, src_start_x + xdiff,
                     dst_start_y, dst_start_x, overlay);
}

int overlay(const WINDOW *src_w, WINDOW *dst_w)
{
    PDC_LOG(("overlay() - called\n"));

    return _copy_overlap(src_w, dst_w, TRUE);
}

int overwrite(const WINDOW *src_w, WINDOW *dst_w)
{
    PDC_LOG(("overwrite() - called\n"));

    return _copy_overlap(src_w, dst_w, FALSE);
}

int copywin(const WINDOW *src_w, WINDOW *dst_w, int src_tr, int src_tc,
            int dst_tr, int dst_tc, int dst_br, int dst_bc, int _overlay)
{
    int src_end_x, src_end_y;
    int src_rows, src_cols, dst_rows, dst_cols;
    int min_rows, min_cols;

    PDC_LOG(("copywin() - called\n"));

    if (!src_w || !dst_w || dst_w == curscr || dst_br >= dst_w->_maxy
        || dst_bc >= dst_w->_maxx || dst_tr < 0 || dst_tc < 0)
        return ERR;

    src_rows = src_w->_maxy - src_tr;
    src_cols = src_w->_maxx - src_tc;
    dst_rows = dst_br - dst_tr + 1;
    dst_cols = dst_bc - dst_tc + 1;

    min_rows = min(src_rows, dst_rows);
    min_cols = min(src_cols, dst_cols);

    src_end_y = src_tr + min_rows;
    src_end_x = src_tc + min_cols;

    return _copy_win(src_w, dst_w, src_tr, src_tc, src_end_y, src_end_x,
                     dst_tr, dst_tc, _overlay);
}
