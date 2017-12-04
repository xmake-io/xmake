/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

scanw
-----

### Synopsis

    int scanw(const char *fmt, ...);
    int wscanw(WINDOW *win, const char *fmt, ...);
    int mvscanw(int y, int x, const char *fmt, ...);
    int mvwscanw(WINDOW *win, int y, int x, const char *fmt, ...);
    int vwscanw(WINDOW *win, const char *fmt, va_list varglist);
    int vw_scanw(WINDOW *win, const char *fmt, va_list varglist);

### Description

   These routines correspond to the standard C library's scanf()
   family. Each gets a string from the window via wgetnstr(), and
   uses the resulting line as input for the scan.

### Return Value

   On successful completion, these functions return the number of
   items successfully matched.  Otherwise they return ERR.

### Portability
                             X/Open    BSD    SYS V
    scanw                       Y       Y       Y
    wscanw                      Y       Y       Y
    mvscanw                     Y       Y       Y
    mvwscanw                    Y       Y       Y
    vwscanw                     Y       -      4.0
    vw_scanw                    Y

**man-end****************************************************************/

#include <string.h>

#ifndef HAVE_VSSCANF
# include <stdlib.h>
# include <ctype.h>
# include <limits.h>

static int _pdc_vsscanf(const char *, const char *, va_list);

# define vsscanf _pdc_vsscanf
#endif

int vwscanw(WINDOW *win, const char *fmt, va_list varglist)
{
    char scanbuf[256];

    PDC_LOG(("vwscanw() - called\n"));

    if (wgetnstr(win, scanbuf, 255) == ERR)
        return ERR;

    return vsscanf(scanbuf, fmt, varglist);
}

int scanw(const char *fmt, ...)
{
    va_list args;
    int retval;

    PDC_LOG(("scanw() - called\n"));

    va_start(args, fmt);
    retval = vwscanw(stdscr, fmt, args);
    va_end(args);

    return retval;
}

int wscanw(WINDOW *win, const char *fmt, ...)
{
    va_list args;
    int retval;

    PDC_LOG(("wscanw() - called\n"));

    va_start(args, fmt);
    retval = vwscanw(win, fmt, args);
    va_end(args);

    return retval;
}

int mvscanw(int y, int x, const char *fmt, ...)
{
    va_list args;
    int retval;

    PDC_LOG(("mvscanw() - called\n"));

    if (move(y, x) == ERR)
        return ERR;

    va_start(args, fmt);
    retval = vwscanw(stdscr, fmt, args);
    va_end(args);

    return retval;
}

int mvwscanw(WINDOW *win, int y, int x, const char *fmt, ...)
{
    va_list args;
    int retval;

    PDC_LOG(("mvscanw() - called\n"));

    if (wmove(win, y, x) == ERR)
        return ERR;

    va_start(args, fmt);
    retval = vwscanw(win, fmt, args);
    va_end(args);

    return retval;
}

int vw_scanw(WINDOW *win, const char *fmt, va_list varglist)
{
    PDC_LOG(("vw_scanw() - called\n"));

    return vwscanw(win, fmt, varglist);
}

#ifndef HAVE_VSSCANF

/* _pdc_vsscanf() - Internal routine to parse and format an input 
   buffer. It scans a series of input fields; each field is formatted 
   according to a supplied format string and the formatted input is 
   stored in the variable number of addresses passed. Returns the number 
   of input fields or EOF on error.

   Don't compile this unless required. Some compilers (at least Borland 
   C++ 3.0) have to link with math libraries due to the use of floats.

   Based on vsscanf.c and input.c from emx 0.8f library source, 
   Copyright (c) 1990-1992 by Eberhard Mattes, who has kindly agreed to 
   its inclusion in PDCurses. */

#define WHITE(x) ((x) == ' ' || (x) == '\t' || (x) == '\n')

#define NEXT(x) \
        do { \
            x = *buf++; \
            if (!x) \
               return (count ? count : EOF); \
            ++chars; \
           } while (0)

#define UNGETC() \
        do { \
            --buf; --chars; \
           } while (0)

static int _pdc_vsscanf(const char *buf, const char *fmt, va_list arg_ptr)
{
    int count, chars, c, width, radix, d, i;
    int *int_ptr;
    long *long_ptr;
    short *short_ptr;
    char *char_ptr;
    unsigned char f;
    char neg, assign, ok, size;
    long n;
    char map[256], end;
    double dx, dd, *dbl_ptr;
    float *flt_ptr;
    int exp;
    char eneg;

    count = 0;
    chars = 0;
    c = 0;
    while ((f = *fmt) != 0)
    {
        if (WHITE(f))
        {
            do
            {
                ++fmt;
                f = *fmt;
            }
            while (WHITE(f));
            do
            {
                c = *buf++;
                if (!c)
                {
                    if (!f || count)
                        return count;
                    else
                        return EOF;
                } else
                    ++chars;
            }
            while (WHITE(c));
            UNGETC();
        } else if (f != '%')
        {
            NEXT(c);
            if (c != f)
                return count;
            ++fmt;
        } else
        {
            assign = TRUE;
            width = INT_MAX;
            char_ptr = NULL;
            ++fmt;
            if (*fmt == '*')
            {
                assign = FALSE;
                ++fmt;
            }
            if (isdigit(*fmt))
            {
                width = 0;
                while (isdigit(*fmt))
                    width = width * 10 + (*fmt++ - '0');
                if (!width)
                    width = INT_MAX;
            }
            size = 0;
            if (*fmt == 'h' || *fmt == 'l')
                size = *fmt++;
            f = *fmt;
            switch (f)
            {
            case 'c':
                if (width == INT_MAX)
                    width = 1;
                if (assign)
                    char_ptr = va_arg(arg_ptr, char *);
                while (width > 0)
                {
                    --width;
                    NEXT(c);
                    if (assign)
                    {
                        *char_ptr++ = (char) c;
                        ++count;
                    }
                }
                break;
            case '[':
                memset(map, 0, 256);
                end = 0;
                ++fmt;
                if (*fmt == '^')
                {
                    ++fmt;
                    end = 1;
                }
                i = 0;
                for (;;)
                {
                    f = (unsigned char) *fmt;
                    switch (f)
                    {
                    case 0:
                        /* avoid skipping past 0 */
                        --fmt;
                        NEXT(c);
                        goto string;
                    case ']':
                        if (i > 0)
                        {
                            NEXT(c);
                            goto string;
                        }
                        /* no break */
                    default:
                        if (fmt[1] == '-' && fmt[2]
                            && f < (unsigned char)fmt[2])
                        {
                            memset(map + f, 1, (unsigned char)fmt[2] - f);
                            fmt += 2;
                        }
                        else
                            map[f] = 1;
                        break;
                    }
                    ++fmt;
                    ++i;
                }
            case 's':
                memset(map, 0, 256);
                map[' '] = 1;
                map['\n'] = 1;
                map['\r'] = 1;
                map['\t'] = 1;
                end = 1;
                do
                {
                    NEXT(c);
                }
                while (WHITE(c));
            string:
                if (assign)
                    char_ptr = va_arg(arg_ptr, char *);
                while (width > 0 && map[(unsigned char) c] != end)
                {
                    --width;
                    if (assign)
                        *char_ptr++ = (char) c;
                    c = *buf++;
                    if (!c)
                        break;
                    else
                        ++chars;
                }
                if (assign)
                {
                    *char_ptr = 0;
                    ++count;
                }
                if (!c)
                    return count;
                else
                    UNGETC();
                break;
            case 'f':
            case 'e':
            case 'E':
            case 'g':
            case 'G':
                neg = ok = FALSE;
                dx = 0.0;
                do
                {
                    NEXT(c);
                }
                while (WHITE(c));
                if (c == '+')
                {
                    NEXT(c);
                    --width;
                } else if (c == '-')
                {
                    neg = TRUE;
                    NEXT(c);
                    --width;
                }
                while (width > 0 && isdigit(c))
                {
                    --width;
                    dx = dx * 10.0 + (double) (c - '0');
                    ok = TRUE;
                    c = *buf++;
                    if (!c)
                        break;
                    else
                        ++chars;
                }
                if (width > 0 && c == '.')
                {
                    --width;
                    dd = 10.0;
                    NEXT(c);
                    while (width > 0 && isdigit(c))
                    {
                        --width;
                        dx += (double) (c - '0') / dd;
                        dd *= 10.0;
                        ok = TRUE;
                        c = *buf++;
                        if (!c)
                            break;
                        else
                            ++chars;
                    }
                }
                if (!ok)
                    return count;
                if (width > 0 && (c == 'e' || c == 'E'))
                {
                    eneg = FALSE;
                    exp = 0;
                    NEXT(c);
                    --width;
                    if (width > 0 && c == '+')
                    {
                        NEXT(c);
                        --width;
                    } else if (width > 0 && c == '-')
                    {
                        eneg = TRUE;
                        NEXT(c);
                        --width;
                    }
                    if (!(width > 0 && isdigit(c)))
                    {
                        UNGETC();
                        return count;
                    }
                    while (width > 0 && isdigit(c))
                    {
                        --width;
                        exp = exp * 10 + (c - '0');
                        c = *buf++;
                        if (!c)
                            break;
                        else
                            ++chars;
                    }
                    if (eneg)
                        exp = -exp;
                    while (exp > 0)
                    {
                        dx *= 10.0;
                        --exp;
                    }
                    while (exp < 0)
                    {
                        dx /= 10.0;
                        ++exp;
                    }
                }
                if (assign)
                {
                    if (neg)
                        dx = -dx;
                    if (size == 'l')
                    {
                        dbl_ptr = va_arg(arg_ptr, double *);
                        *dbl_ptr = dx;
                    }
                    else
                    {
                        flt_ptr = va_arg(arg_ptr, float *);
                        *flt_ptr = (float)dx;
                    }
                    ++count;
                }
                if (!c)
                    return count;
                else
                    UNGETC();
                break;
            case 'i':
                neg = FALSE;
                radix = 10;
                do
                {
                    NEXT(c);
                }
                while (WHITE(c));
                if (!(width > 0 && c == '0'))
                    goto scan_complete_number;
                NEXT(c);
                --width;
                if (width > 0 && (c == 'x' || c == 'X'))
                {
                    NEXT(c);
                    radix = 16;
                    --width;
                }
                else if (width > 0 && (c >= '0' && c <= '7'))
                    radix = 8;
                goto scan_unsigned_number;
            case 'd':
            case 'u':
            case 'o':
            case 'x':
            case 'X':
                do
                {
                    NEXT(c);
                }
                while (WHITE(c));
                switch (f)
                {
                case 'o':
                    radix = 8;
                    break;
                case 'x':
                case 'X':
                    radix = 16;
                    break;
                default:
                    radix = 10;
                    break;
                }
            scan_complete_number:
                neg = FALSE;
                if (width > 0 && c == '+')
                {
                    NEXT(c);
                    --width;
                }
                else if (width > 0 && c == '-' && radix == 10)
                {
                    neg = TRUE;
                    NEXT(c);
                    --width;
                }
            scan_unsigned_number:
                n = 0;
                ok = FALSE;
                while (width > 0)
                {
                    --width;
                    if (isdigit(c))
                        d = c - '0';
                    else if (isupper(c))
                        d = c - 'A' + 10;
                    else if (islower(c))
                        d = c - 'a' + 10;
                    else
                        break;
                    if (d < 0 || d >= radix)
                        break;
                    ok = TRUE;
                    n = n * radix + d;
                    c = *buf++;
                    if (!c)
                        break;
                    else
                        ++chars;
                }
                if (!ok)
                    return count;
                if (assign)
                {
                    if (neg)
                        n = -n;
                    switch (size)
                    {
                    case 'h':
                        short_ptr = va_arg(arg_ptr, short *);
                        *short_ptr = (short) n;
                        break;
                    case 'l':
                        long_ptr = va_arg(arg_ptr, long *);
                        *long_ptr = (long) n;
                        break;
                    default:
                        int_ptr = va_arg(arg_ptr, int *);
                        *int_ptr = (int) n;
                    }
                    ++count;
                }
                if (!c)
                    return count;
                else
                    UNGETC();
                break;
            case 'n':
                if (assign)
                {
                    int_ptr = va_arg(arg_ptr, int *);
                    *int_ptr = chars;
                    ++count;
                }
                break;
            default:
                if (!f) /* % at end of string */
                    return count;
                NEXT(c);
                if (c != f)
                    return count;
                break;
            }
            ++fmt;
        }
    }
    return count;
}
#endif /* HAVE_VSSCANF */
