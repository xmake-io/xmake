/* Public Domain Curses */

#include "pdcwin.h"
#include <stdio.h>
#include <stdlib.h>
#include <malloc.h>

#ifdef CHTYPE_LONG
# define PDC_OFFSET 32
#else
# define PDC_OFFSET  8
#endif

#ifdef _WIN32
#pragma warning(disable: 4996)
#endif

/* COLOR_PAIR to attribute encoding table. */

unsigned char *pdc_atrtab = (unsigned char *)NULL;

HANDLE std_con_out = INVALID_HANDLE_VALUE;
HANDLE pdc_con_out = INVALID_HANDLE_VALUE;
HANDLE pdc_con_in = INVALID_HANDLE_VALUE;

DWORD pdc_quick_edit;

static short curstoreal[16], realtocurs[16] =
{
    COLOR_BLACK, COLOR_BLUE, COLOR_GREEN, COLOR_CYAN, COLOR_RED,
    COLOR_MAGENTA, COLOR_YELLOW, COLOR_WHITE, COLOR_BLACK + 8,
    COLOR_BLUE + 8, COLOR_GREEN + 8, COLOR_CYAN + 8, COLOR_RED + 8,
    COLOR_MAGENTA + 8, COLOR_YELLOW + 8, COLOR_WHITE + 8
};

enum { PDC_RESTORE_NONE, PDC_RESTORE_BUFFER };

/* Struct for storing console registry keys, and for use with the 
   undocumented WM_SETCONSOLEINFO message. Originally by James Brown, 
   www.catch22.net. */

static struct
{
    ULONG    Length;
    COORD    ScreenBufferSize;
    COORD    WindowSize;
    ULONG    WindowPosX;
    ULONG    WindowPosY;

    COORD    FontSize;
    ULONG    FontFamily;
    ULONG    FontWeight;
    WCHAR    FaceName[32];

    ULONG    CursorSize;
    ULONG    FullScreen;
    ULONG    QuickEdit;
    ULONG    AutoPosition;
    ULONG    InsertMode;
    
    USHORT   ScreenColors;
    USHORT   PopupColors;
    ULONG    HistoryNoDup;
    ULONG    HistoryBufferSize;
    ULONG    NumberOfHistoryBuffers;
    
    COLORREF ColorTable[16];

    ULONG    CodePage;
    HWND     Hwnd;

    WCHAR    ConsoleTitle[0x100];
} console_info;

#ifndef HAVE_INFOEX
/* Console screen buffer information (extended version) */
typedef struct _CONSOLE_SCREEN_BUFFER_INFOEX {
    ULONG       cbSize;
    COORD       dwSize;
    COORD       dwCursorPosition;
    WORD        wAttributes;
    SMALL_RECT  srWindow;
    COORD       dwMaximumWindowSize;
    WORD        wPopupAttributes;
    BOOL        bFullscreenSupported;
    COLORREF    ColorTable[16];
} CONSOLE_SCREEN_BUFFER_INFOEX;
typedef CONSOLE_SCREEN_BUFFER_INFOEX    *PCONSOLE_SCREEN_BUFFER_INFOEX;
#endif

typedef BOOL (WINAPI *SetConsoleScreenBufferInfoExFn)(HANDLE hConsoleOutput,
    PCONSOLE_SCREEN_BUFFER_INFOEX lpConsoleScreenBufferInfoEx);
typedef BOOL (WINAPI *GetConsoleScreenBufferInfoExFn)(HANDLE hConsoleOutput,
    PCONSOLE_SCREEN_BUFFER_INFOEX lpConsoleScreenBufferInfoEx);

static SetConsoleScreenBufferInfoExFn pSetConsoleScreenBufferInfoEx = NULL;
static GetConsoleScreenBufferInfoExFn pGetConsoleScreenBufferInfoEx = NULL;

static CONSOLE_SCREEN_BUFFER_INFO orig_scr;
static CONSOLE_SCREEN_BUFFER_INFOEX console_infoex;

static LPTOP_LEVEL_EXCEPTION_FILTER xcpt_filter;

static DWORD old_console_mode = 0;

static bool is_nt;

static HWND _find_console_handle(void)
{
    TCHAR orgtitle[1024], temptitle[1024];
    HWND wnd;

    GetConsoleTitle(orgtitle, 1024);

    wsprintf(temptitle, TEXT("%d/%d"), GetTickCount(), GetCurrentProcessId());
    SetConsoleTitle(temptitle);

    Sleep(40);

    wnd = FindWindow(NULL, temptitle);

    SetConsoleTitle(orgtitle);

    return wnd;
}

/* Undocumented console message */

#define WM_SETCONSOLEINFO (WM_USER + 201)

/* Wrapper around WM_SETCONSOLEINFO. We need to create the necessary 
   section (file-mapping) object in the context of the process which 
   owns the console, before posting the message. Originally by JB. */

static void _set_console_info(void)
{
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    CONSOLE_CURSOR_INFO cci;
    DWORD dwConsoleOwnerPid;
    HANDLE hProcess;
    HANDLE hSection, hDupSection;
    PVOID ptrView;

    /* Each-time initialization for console_info */

    GetConsoleCursorInfo(pdc_con_out, &cci);
    console_info.CursorSize = cci.dwSize;

    GetConsoleScreenBufferInfo(pdc_con_out, &csbi);
    console_info.ScreenBufferSize = csbi.dwSize;

    console_info.WindowSize.X = csbi.srWindow.Right - csbi.srWindow.Left + 1;
    console_info.WindowSize.Y = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;

    console_info.WindowPosX = csbi.srWindow.Left;
    console_info.WindowPosY = csbi.srWindow.Top;

    /* Open the process which "owns" the console */

    GetWindowThreadProcessId(console_info.Hwnd, &dwConsoleOwnerPid);
    
    hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, dwConsoleOwnerPid);

    /* Create a SECTION object backed by page-file, then map a view of
       this section into the owner process so we can write the contents
       of the CONSOLE_INFO buffer into it */

    hSection = CreateFileMapping(INVALID_HANDLE_VALUE, 0, PAGE_READWRITE,
                                 0, sizeof(console_info), 0);

    /* Copy our console structure into the section-object */

    ptrView = MapViewOfFile(hSection, FILE_MAP_WRITE|FILE_MAP_READ,
                            0, 0, sizeof(console_info));

    memcpy(ptrView, &console_info, sizeof(console_info));

    UnmapViewOfFile(ptrView);

    /* Map the memory into owner process */

    DuplicateHandle(GetCurrentProcess(), hSection, hProcess, &hDupSection,
                    0, FALSE, DUPLICATE_SAME_ACCESS);

    /* Send console window the "update" message */

    SendMessage(console_info.Hwnd, WM_SETCONSOLEINFO, (WPARAM)hDupSection, 0);

    CloseHandle(hSection);
    CloseHandle(hProcess);
}

static int _set_console_infoex(void)
{
    if (!pSetConsoleScreenBufferInfoEx(pdc_con_out, &console_infoex))
        return ERR;

    return OK;
}

static int _set_colors(void)
{
    if (pSetConsoleScreenBufferInfoEx)
        return _set_console_infoex();
    else
    {
        _set_console_info();
        return OK;
    }
}

/* One-time initialization for console_info -- color table and font info
   from the registry; other values from functions. */

static void _init_console_info(void)
{
    DWORD scrnmode, len;
    HKEY reghnd;
    int i;

    console_info.Hwnd = _find_console_handle();
    console_info.Length = sizeof(console_info);

    GetConsoleMode(pdc_con_in, &scrnmode);
    console_info.QuickEdit = !!(scrnmode & 0x0040);
    console_info.InsertMode = !!(scrnmode & 0x0020);

    console_info.FullScreen = FALSE;
    console_info.AutoPosition = 0x10000;
    console_info.ScreenColors = SP->orig_back << 4 | SP->orig_fore;
    console_info.PopupColors = 0xf5;
    
    console_info.HistoryNoDup = FALSE;
    console_info.HistoryBufferSize = 50;
    console_info.NumberOfHistoryBuffers = 4;

    console_info.CodePage = GetConsoleOutputCP();

    RegOpenKeyEx(HKEY_CURRENT_USER, TEXT("Console"), 0,
                 KEY_QUERY_VALUE, &reghnd);

    len = sizeof(DWORD);

    /* Default color table */

    for (i = 0; i < 16; i++)
    {
        char tname[13];

        sprintf(tname, "ColorTable%02d", i);
        RegQueryValueExA(reghnd, tname, NULL, NULL,
                         (LPBYTE)(&(console_info.ColorTable[i])), &len);
    }

    /* Font info */

    RegQueryValueEx(reghnd, TEXT("FontSize"), NULL, NULL,
                    (LPBYTE)(&console_info.FontSize), &len);
    RegQueryValueEx(reghnd, TEXT("FontFamily"), NULL, NULL,
                    (LPBYTE)(&console_info.FontFamily), &len);
    RegQueryValueEx(reghnd, TEXT("FontWeight"), NULL, NULL,
                    (LPBYTE)(&console_info.FontWeight), &len);

    len = sizeof(WCHAR) * 32;
    RegQueryValueExW(reghnd, L"FaceName", NULL, NULL,
                     (LPBYTE)(console_info.FaceName), &len);

    RegCloseKey(reghnd);
}

static int _init_console_infoex(void)
{
    console_infoex.cbSize = sizeof(console_infoex);

    if (!pGetConsoleScreenBufferInfoEx(pdc_con_out, &console_infoex))
        return ERR;

    console_infoex.srWindow.Right++;
    console_infoex.srWindow.Bottom++;

    return OK;
}

static COLORREF *_get_colors(void)
{
    if (pGetConsoleScreenBufferInfoEx)
    {
        int status = OK;
        if (!console_infoex.cbSize)
            status = _init_console_infoex();
        return (status == ERR) ? NULL :
            (COLORREF *)(&(console_infoex.ColorTable));
    }
    else
    {
        if (!console_info.Hwnd)
            _init_console_info();
        return (COLORREF *)(&(console_info.ColorTable));
    }
}

/* restore the original console buffer in the event of a crash */

static LONG WINAPI _restore_console(LPEXCEPTION_POINTERS ep)
{
    PDC_scr_close();

    return EXCEPTION_CONTINUE_SEARCH;
}

/* restore the original console buffer on Ctrl+Break (or Ctrl+C,
   if it gets re-enabled) */

static BOOL WINAPI _ctrl_break(DWORD dwCtrlType)
{
    if (dwCtrlType == CTRL_BREAK_EVENT || dwCtrlType == CTRL_C_EVENT)
        PDC_scr_close();

    return FALSE;
}

/* close the physical screen -- may restore the screen to its state
   before PDC_scr_open(); miscellaneous cleanup */

void PDC_scr_close(void)
{
    PDC_LOG(("PDC_scr_close() - called\n"));

    if (SP->visibility != 1)
        curs_set(1);

    PDC_reset_shell_mode();

    /* Position cursor to the bottom left of the screen. */

    if (SP->_restore == PDC_RESTORE_NONE)
    {
        SMALL_RECT win;

        win.Left = orig_scr.srWindow.Left;
        win.Right = orig_scr.srWindow.Right;
        win.Top = 0;
        win.Bottom = orig_scr.srWindow.Bottom - orig_scr.srWindow.Top;
        SetConsoleWindowInfo(pdc_con_out, TRUE, &win);
        PDC_gotoyx(win.Bottom, 0);
    }
}

void PDC_scr_free(void)
{
    if (SP)
        free(SP);
    if (pdc_atrtab)
        free(pdc_atrtab);

    pdc_atrtab = (unsigned char *)NULL;

    if (pdc_con_out != std_con_out)
    {
        CloseHandle(pdc_con_out);
        pdc_con_out = std_con_out;
    }

    SetUnhandledExceptionFilter(xcpt_filter);
    SetConsoleCtrlHandler(_ctrl_break, FALSE);
}

/* open the physical screen -- allocate SP, miscellaneous intialization,
   and may save the existing screen for later restoration */

int PDC_scr_open(int argc, char **argv)
{
    const char *str;
    CONSOLE_SCREEN_BUFFER_INFO csbi;
    HMODULE h_kernel;
    int i;

    PDC_LOG(("PDC_scr_open() - called\n"));

    SP = calloc(1, sizeof(SCREEN));
    pdc_atrtab = calloc(PDC_COLOR_PAIRS * PDC_OFFSET, 1);

    if (!SP || !pdc_atrtab)
        return ERR;

    for (i = 0; i < 16; i++)
        curstoreal[realtocurs[i]] = i;

    std_con_out =
    pdc_con_out = GetStdHandle(STD_OUTPUT_HANDLE);
    pdc_con_in = GetStdHandle(STD_INPUT_HANDLE);

    if (GetFileType(pdc_con_in) != FILE_TYPE_CHAR)
    {
        fprintf(stderr, "\nRedirection is not supported.\n");
        exit(1);
    }

    is_nt = !(GetVersion() & 0x80000000);

    GetConsoleScreenBufferInfo(pdc_con_out, &csbi);
    GetConsoleScreenBufferInfo(pdc_con_out, &orig_scr);
    GetConsoleMode(pdc_con_in, &old_console_mode);

    /* preserve QuickEdit Mode setting for use in PDC_mouse_set() when
       the mouse is not enabled -- other console input settings are
       cleared */

    pdc_quick_edit = old_console_mode & 0x0040;

    SP->lines = (str = getenv("LINES")) ? atoi(str) : PDC_get_rows();
    SP->cols = (str = getenv("COLS")) ? atoi(str) : PDC_get_columns();

    SP->mouse_wait = PDC_CLICK_PERIOD;
    SP->audible = TRUE;

    if (SP->lines < 2 || SP->lines > csbi.dwMaximumWindowSize.Y)
    {
        fprintf(stderr, "LINES value must be >= 2 and <= %d: got %d\n",
                csbi.dwMaximumWindowSize.Y, SP->lines);

        return ERR;
    }

    if (SP->cols < 2 || SP->cols > csbi.dwMaximumWindowSize.X)
    {
        fprintf(stderr, "COLS value must be >= 2 and <= %d: got %d\n",
                csbi.dwMaximumWindowSize.X, SP->cols);

        return ERR;
    }

    SP->orig_fore = csbi.wAttributes & 0x0f;
    SP->orig_back = (csbi.wAttributes & 0xf0) >> 4;

    SP->orig_attr = TRUE;

    SP->_restore = PDC_RESTORE_NONE;

    if ((str = getenv("PDC_RESTORE_SCREEN")) == NULL || *str != '0')
    {
        /* Create a new console buffer */

        pdc_con_out =
            CreateConsoleScreenBuffer(GENERIC_READ | GENERIC_WRITE,
                                      FILE_SHARE_READ | FILE_SHARE_WRITE,
                                      NULL, CONSOLE_TEXTMODE_BUFFER, NULL);

        if (pdc_con_out == INVALID_HANDLE_VALUE)
        {
            PDC_LOG(("PDC_scr_open() - screen buffer failure\n"));

            pdc_con_out = std_con_out;
        }
        else
            SP->_restore = PDC_RESTORE_BUFFER;
    }

    xcpt_filter = SetUnhandledExceptionFilter(_restore_console);
    SetConsoleCtrlHandler(_ctrl_break, TRUE);

    SP->_preserve = (getenv("PDC_PRESERVE_SCREEN") != NULL);

    PDC_reset_prog_mode();

    SP->mono = FALSE;

    h_kernel = GetModuleHandleA("kernel32.dll");
    pGetConsoleScreenBufferInfoEx =
        (GetConsoleScreenBufferInfoExFn)GetProcAddress(h_kernel,
        "GetConsoleScreenBufferInfoEx");
    pSetConsoleScreenBufferInfoEx =
        (SetConsoleScreenBufferInfoExFn)GetProcAddress(h_kernel,
        "SetConsoleScreenBufferInfoEx");

    return OK;
}

 /* Calls SetConsoleWindowInfo with the given parameters, but fits them 
    if a scoll bar shrinks the maximum possible value. The rectangle 
    must at least fit in a half-sized window. */

static BOOL _fit_console_window(HANDLE con_out, CONST SMALL_RECT *rect)
{
    SMALL_RECT run;
    SHORT mx, my;

    if (SetConsoleWindowInfo(con_out, TRUE, rect))
        return TRUE;

    run = *rect;
    run.Right /= 2;
    run.Bottom /= 2;

    mx = run.Right;
    my = run.Bottom;

    if (!SetConsoleWindowInfo(con_out, TRUE, &run))
        return FALSE;

    for (run.Right = rect->Right; run.Right >= mx; run.Right--)
        if (SetConsoleWindowInfo(con_out, TRUE, &run))
            break;

    if (run.Right < mx)
        return FALSE;

    for (run.Bottom = rect->Bottom; run.Bottom >= my; run.Bottom--)
        if (SetConsoleWindowInfo(con_out, TRUE, &run))
            return TRUE;

    return FALSE;
}

/* the core of resize_term() */

int PDC_resize_screen(int nlines, int ncols)
{
    SMALL_RECT rect;
    COORD size, max;

    if (nlines < 2 || ncols < 2)
        return ERR;

    max = GetLargestConsoleWindowSize(pdc_con_out);

    rect.Left = rect.Top = 0;
    rect.Right = ncols - 1;

    if (rect.Right > max.X)
        rect.Right = max.X;

    rect.Bottom = nlines - 1;

    if (rect.Bottom > max.Y)
        rect.Bottom = max.Y;

    size.X = rect.Right + 1;
    size.Y = rect.Bottom + 1;

    _fit_console_window(pdc_con_out, &rect);
    SetConsoleScreenBufferSize(pdc_con_out, size);
    _fit_console_window(pdc_con_out, &rect);
    SetConsoleScreenBufferSize(pdc_con_out, size);
    SetConsoleActiveScreenBuffer(pdc_con_out);

    return OK;
}

void PDC_reset_prog_mode(void)
{
    PDC_LOG(("PDC_reset_prog_mode() - called.\n"));

    if (pdc_con_out != std_con_out)
        SetConsoleActiveScreenBuffer(pdc_con_out);
    else if (is_nt)
    {
        COORD bufsize;
        SMALL_RECT rect;

        bufsize.X = orig_scr.srWindow.Right - orig_scr.srWindow.Left + 1;
        bufsize.Y = orig_scr.srWindow.Bottom - orig_scr.srWindow.Top + 1;

        rect.Top = rect.Left = 0;
        rect.Bottom = bufsize.Y - 1;
        rect.Right = bufsize.X - 1;

        SetConsoleScreenBufferSize(pdc_con_out, bufsize);
        SetConsoleWindowInfo(pdc_con_out, TRUE, &rect);
        SetConsoleScreenBufferSize(pdc_con_out, bufsize);
        SetConsoleActiveScreenBuffer(pdc_con_out);
    }

    PDC_mouse_set();
}

void PDC_reset_shell_mode(void)
{
    PDC_LOG(("PDC_reset_shell_mode() - called.\n"));

    if (pdc_con_out != std_con_out)
        SetConsoleActiveScreenBuffer(std_con_out);
    else if (is_nt)
    {
        SetConsoleScreenBufferSize(pdc_con_out, orig_scr.dwSize);
        SetConsoleWindowInfo(pdc_con_out, TRUE, &orig_scr.srWindow);
        SetConsoleScreenBufferSize(pdc_con_out, orig_scr.dwSize);
        SetConsoleWindowInfo(pdc_con_out, TRUE, &orig_scr.srWindow);
        SetConsoleActiveScreenBuffer(pdc_con_out);
    }

    SetConsoleMode(pdc_con_in, old_console_mode);
}

void PDC_restore_screen_mode(int i)
{
}

void PDC_save_screen_mode(int i)
{
}

void PDC_init_pair(short pair, short fg, short bg)
{
    unsigned char att, temp_bg;
    chtype i;

    fg = curstoreal[fg];
    bg = curstoreal[bg];

    for (i = 0; i < PDC_OFFSET; i++)
    {
        att = fg | (bg << 4);

        if (i & (A_REVERSE >> PDC_ATTR_SHIFT))
            att = bg | (fg << 4);
        if (i & (A_UNDERLINE >> PDC_ATTR_SHIFT))
            att = 1;
        if (i & (A_INVIS >> PDC_ATTR_SHIFT))
        {
            temp_bg = att >> 4;
            att = temp_bg << 4 | temp_bg;
        }
        if (i & (A_BOLD >> PDC_ATTR_SHIFT))
            att |= 8;
        if (i & (A_BLINK >> PDC_ATTR_SHIFT))
            att |= 128;

        pdc_atrtab[pair * PDC_OFFSET + i] = att;
    }
}

int PDC_pair_content(short pair, short *fg, short *bg)
{
    *fg = realtocurs[pdc_atrtab[pair * PDC_OFFSET] & 0x0F];
    *bg = realtocurs[(pdc_atrtab[pair * PDC_OFFSET] & 0xF0) >> 4];

    return OK;
}

bool PDC_can_change_color(void)
{
    return is_nt;
}

int PDC_color_content(short color, short *red, short *green, short *blue)
{
    COLORREF *color_table = _get_colors();

    if (color_table)
    {
        DWORD col = color_table[curstoreal[color]];

        *red = DIVROUND(GetRValue(col) * 1000, 255);
        *green = DIVROUND(GetGValue(col) * 1000, 255);
        *blue = DIVROUND(GetBValue(col) * 1000, 255);

        return OK;
    }

    return ERR;
}

int PDC_init_color(short color, short red, short green, short blue)
{
    COLORREF *color_table = _get_colors();

    if (color_table)
    {
        color_table[curstoreal[color]] =
            RGB(DIVROUND(red * 255, 1000),
                DIVROUND(green * 255, 1000),
                DIVROUND(blue * 255, 1000));

        return _set_colors();
    }

    return ERR;
}
