/* Public Domain Curses */

#include "pdcwin.h"

/*man-start**************************************************************

clipboard
---------

### Synopsis

    int PDC_getclipboard(char **contents, long *length);
    int PDC_setclipboard(const char *contents, long length);
    int PDC_freeclipboard(char *contents);
    int PDC_clearclipboard(void);

### Description

   PDC_getclipboard() gets the textual contents of the system's
   clipboard. This function returns the contents of the clipboard
   in the contents argument. It is the responsibilitiy of the
   caller to free the memory returned, via PDC_freeclipboard().
   The length of the clipboard contents is returned in the length
   argument.

   PDC_setclipboard copies the supplied text into the system's
   clipboard, emptying the clipboard prior to the copy.

   PDC_clearclipboard() clears the internal clipboard.

### Return Values

   indicator of success/failure of call.
   PDC_CLIP_SUCCESS        the call was successful
   PDC_CLIP_MEMORY_ERROR   unable to allocate sufficient memory for
                           the clipboard contents
   PDC_CLIP_EMPTY          the clipboard contains no text
   PDC_CLIP_ACCESS_ERROR   no clipboard support

### Portability
                             X/Open    BSD    SYS V
    PDC_getclipboard            -       -       -
    PDC_setclipboard            -       -       -
    PDC_freeclipboard           -       -       -
    PDC_clearclipboard          -       -       -

**man-end****************************************************************/

#ifdef PDC_WIDE
# define PDC_TEXT CF_UNICODETEXT
#else
# define PDC_TEXT CF_OEMTEXT
#endif

int PDC_getclipboard(char **contents, long *length)
{
    HANDLE handle;
    long len;

    PDC_LOG(("PDC_getclipboard() - called\n"));

    if (!OpenClipboard(NULL))
        return PDC_CLIP_ACCESS_ERROR;

    if ((handle = GetClipboardData(PDC_TEXT)) == NULL)
    {
        CloseClipboard();
        return PDC_CLIP_EMPTY;
    }

#ifdef PDC_WIDE
    len = (long)wcslen((wchar_t *)handle) * 3;
#else
    len = strlen((char *)handle);
#endif
    *contents = (char *)GlobalAlloc(GMEM_FIXED, len + 1);

    if (!*contents)
    {
        CloseClipboard();
        return PDC_CLIP_MEMORY_ERROR;
    }

#ifdef PDC_WIDE
    len = (long)PDC_wcstombs((char *)*contents, (wchar_t *)handle, len);
#else
    strcpy((char *)*contents, (char *)handle);
#endif
    *length = len;
    CloseClipboard();

    return PDC_CLIP_SUCCESS;
}

int PDC_setclipboard(const char *contents, long length)
{
    HGLOBAL ptr1;
    LPTSTR ptr2;

    PDC_LOG(("PDC_setclipboard() - called\n"));

    if (!OpenClipboard(NULL))
        return PDC_CLIP_ACCESS_ERROR;

    ptr1 = GlobalAlloc(GMEM_MOVEABLE|GMEM_DDESHARE, 
        (length + 1) * sizeof(TCHAR));

    if (!ptr1)
        return PDC_CLIP_MEMORY_ERROR;

    ptr2 = (LPTSTR)GlobalLock(ptr1);

#ifdef PDC_WIDE
    PDC_mbstowcs((wchar_t *)ptr2, contents, length);
#else
    memcpy((char *)ptr2, contents, length + 1);
#endif
    GlobalUnlock(ptr1);
    EmptyClipboard();

    if (!SetClipboardData(PDC_TEXT, ptr1))
    {
        GlobalFree(ptr1);
        return PDC_CLIP_ACCESS_ERROR;
    }

    CloseClipboard();
    GlobalFree(ptr1);

    return PDC_CLIP_SUCCESS;
}

int PDC_freeclipboard(char *contents)
{
    PDC_LOG(("PDC_freeclipboard() - called\n"));

    GlobalFree(contents);
    return PDC_CLIP_SUCCESS;
}

int PDC_clearclipboard(void)
{
    PDC_LOG(("PDC_clearclipboard() - called\n"));

    EmptyClipboard();

    return PDC_CLIP_SUCCESS;
}
