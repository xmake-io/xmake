/* Public Domain Curses */

#include <curspriv.h>

/*man-start**************************************************************

util
----

### Synopsis

    char *unctrl(chtype c);
    void filter(void);
    void use_env(bool x);
    int delay_output(int ms);

    int getcchar(const cchar_t *wcval, wchar_t *wch, attr_t *attrs,
                 short *color_pair, void *opts);
    int setcchar(cchar_t *wcval, const wchar_t *wch, const attr_t attrs,
                 short color_pair, const void *opts);
    wchar_t *wunctrl(cchar_t *wc);

    int PDC_mbtowc(wchar_t *pwc, const char *s, size_t n);
    size_t PDC_mbstowcs(wchar_t *dest, const char *src, size_t n);
    size_t PDC_wcstombs(char *dest, const wchar_t *src, size_t n);

### Description

   unctrl() expands the text portion of the chtype c into a
   printable string. Control characters are changed to the "^X"
   notation; others are passed through. wunctrl() is the wide-
   character version of the function.

   filter() and use_env() are no-ops in PDCurses.

   delay_output() inserts an ms millisecond pause in output.

   getcchar() works in two modes: When wch is not NULL, it reads
   the cchar_t pointed to by wcval and stores the attributes in
   attrs, the color pair in color_pair, and the text in the
   wide-character string wch. When wch is NULL, getcchar() merely
   returns the number of wide characters in wcval. In either mode,
   the opts argument is unused.

   setcchar constructs a cchar_t at wcval from the wide-character
   text at wch, the attributes in attr and the color pair in
   color_pair. The opts argument is unused.

   Currently, the length returned by getcchar() is always 1 or 0.
   Similarly, setcchar() will only take the first wide character
   from wch, and ignore any others that it "should" take (i.e.,
   combining characters). Nor will it correctly handle any
   character outside the basic multilingual plane (UCS-2).

### Return Value

   unctrl() and wunctrl() return NULL on failure. delay_output()
   always returns OK.

   getcchar() returns the number of wide characters wcval points to
   when wch is NULL; when it's not, getcchar() returns OK or ERR.

   setcchar() returns OK or ERR.

### Portability
                             X/Open    BSD    SYS V
    unctrl                      Y       Y       Y
    filter                      Y       -      3.0
    use_env                     Y       -      4.0
    delay_output                Y       Y       Y
    getcchar                    Y
    setcchar                    Y
    wunctrl                     Y
    PDC_mbtowc                  -       -       -
    PDC_mbstowcs                -       -       -
    PDC_wcstombs                -       -       -

**man-end****************************************************************/

#ifdef PDC_WIDE
# ifdef PDC_FORCE_UTF8
#  include <string.h>
# else
#  include <stdlib.h>
# endif
#endif

char *unctrl(chtype c)
{
    static char strbuf[3] = {0, 0, 0};

    chtype ic;

    PDC_LOG(("unctrl() - called\n"));

    ic = c & A_CHARTEXT;

    if (ic >= 0x20 && ic != 0x7f)       /* normal characters */
    {
        strbuf[0] = (char)ic;
        strbuf[1] = '\0';
        return strbuf;
    }

    strbuf[0] = '^';            /* '^' prefix */

    if (ic == 0x7f)             /* 0x7f == DEL */
        strbuf[1] = '?';
    else                    /* other control */
        strbuf[1] = (char)(ic + '@');

    return strbuf;
}

void filter(void)
{
    PDC_LOG(("filter() - called\n"));
}

void use_env(bool x)
{
    PDC_LOG(("use_env() - called: x %d\n", x));
}

int delay_output(int ms)
{
    PDC_LOG(("delay_output() - called: ms %d\n", ms));

    return napms(ms);
}

#ifdef PDC_WIDE
int getcchar(const cchar_t *wcval, wchar_t *wch, attr_t *attrs,
             short *color_pair, void *opts)
{
    if (!wcval)
        return ERR;

    if (wch)
    {
        if (!attrs || !color_pair)
            return ERR;

        *wch = (*wcval & A_CHARTEXT);
        *attrs = (*wcval & (A_ATTRIBUTES & ~A_COLOR));
        *color_pair = PAIR_NUMBER(*wcval & A_COLOR);

        if (*wch)
            *++wch = L'\0';

        return OK;
    }
    else
        return ((*wcval & A_CHARTEXT) != L'\0');
}

int setcchar(cchar_t *wcval, const wchar_t *wch, const attr_t attrs,
             short color_pair, const void *opts)
{
    if (!wcval || !wch)
        return ERR;

    *wcval = *wch | attrs | COLOR_PAIR(color_pair);

    return OK;
}

wchar_t *wunctrl(cchar_t *wc)
{
    static wchar_t strbuf[3] = {0, 0, 0};

    cchar_t ic;

    PDC_LOG(("wunctrl() - called\n"));

    ic = *wc & A_CHARTEXT;

    if (ic >= 0x20 && ic != 0x7f)       /* normal characters */
    {
        strbuf[0] = (wchar_t)ic;
        strbuf[1] = L'\0';
        return strbuf;
    }

    strbuf[0] = '^';            /* '^' prefix */

    if (ic == 0x7f)             /* 0x7f == DEL */
        strbuf[1] = '?';
    else                    /* other control */
        strbuf[1] = (wchar_t)(ic + '@');

    return strbuf;
}

int PDC_mbtowc(wchar_t *pwc, const char *s, size_t n)
{
# ifdef PDC_FORCE_UTF8
    wchar_t key;
    int i = -1;
    const unsigned char *string;

    if (!s || (n < 1))
        return -1;

    if (!*s)
        return 0;

    string = (const unsigned char *)s;

    key = string[0];

    /* Simplistic UTF-8 decoder -- only does the BMP, minimal validation */

    if (key & 0x80)
    {
        if ((key & 0xe0) == 0xc0)
        {
            if (1 < n)
            {
                key = ((key & 0x1f) << 6) | (string[1] & 0x3f);
                i = 2;
            }
        }
        else if ((key & 0xe0) == 0xe0)
        {
            if (2 < n)
            {
                key = ((key & 0x0f) << 12) | ((string[1] & 0x3f) << 6) |
                      (string[2] & 0x3f);
                i = 3;
            }
        }
    }
    else
        i = 1;

    if (i)
        *pwc = key;

    return i;
# else
    return mbtowc(pwc, s, n);
# endif
}

size_t PDC_mbstowcs(wchar_t *dest, const char *src, size_t n)
{
# ifdef PDC_FORCE_UTF8
    size_t i = 0, len;

    if (!src || !dest)
        return 0;

    len = strlen(src);

    while (*src && i < n)
    {
        int retval = PDC_mbtowc(dest + i, src, len);

        if (retval < 1)
            return -1;

        src += retval;
        len -= retval;
        i++;
    }
# else
    size_t i = mbstowcs(dest, src, n);
# endif
    dest[i] = 0;
    return i;
}

size_t PDC_wcstombs(char *dest, const wchar_t *src, size_t n)
{
# ifdef PDC_FORCE_UTF8
    size_t i = 0;

    if (!src || !dest)
        return 0;

    while (*src && i < n)
    {
        chtype code = *src++;

        if (code < 0x80)
        {
            dest[i] = code;
            i++;
        }
        else
            if (code < 0x800)
            {
                dest[i] = ((code & 0x07c0) >> 6) | 0xc0;
                dest[i + 1] = (code & 0x003f) | 0x80;
                i += 2;
            }
            else
            {
                dest[i] = ((code & 0xf000) >> 12) | 0xe0;
                dest[i + 1] = ((code & 0x0fc0) >> 6) | 0x80;
                dest[i + 2] = (code & 0x003f) | 0x80;
                i += 3;
            }
    }
# else
    size_t i = wcstombs(dest, src, n);
# endif
    dest[i] = '\0';
    return i;
}
#endif
